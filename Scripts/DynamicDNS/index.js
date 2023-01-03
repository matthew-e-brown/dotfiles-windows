const fs = require('fs/promises');
const path = require('path');
const https = require('https');
const { EOL } = require('os');

const API_URL = `https://api-ipv4.porkbun.com/api/json/v3/`;
const LOG_SIZE = 10_000;
const LOG_FILE = path.resolve(__dirname, `./dns.log`);
const CONFIG_FILE = path.resolve(__dirname, `./config.json`);


/**
 * This script uses Porkbun's Dynamic DNS API to update my home's dynamic DNS to my current IP
 * address. It runs every two hours, as long as my desktop is running. It is based off of Porkbun's
 * Python example. It reads from a `.config.json` file that should live next to it in this directory
 * (if that's undesired, change the `path.resolve` line above), and should look like:
 *
 * ```json
 * {
 *      "domain": "borseth.ink",
 *      "subdomain": "www",
 *      "apikey": "YOUR_API_KEY",
 *      "secretapikey": "YOUR_SECRET_API_KEY"
 * }
 * ```
 *
 * It will write its results into `dns.log`, which will also (by default) live next to this script
 * in the same directory.
 *
 * @see {@link https://github.com/porkbundomains/porkbun-dynamic-dns-python}
 */


/**
 * @typedef PorkbunConfig
 * @property {string} domain
 * @property {string} subdomain
 * @property {string} apikey
 * @property {string} secretapikey
 */

/**
 * @typedef PorkbunDNSRecord
 * @property {string} id
 * @property {string} name
 * @property {string} type
 * @property {string} content
 * @property {string} ttl
 * @property {string} prio
 */


/**
 * @param {string} url The Porkbun endpoint to hit
 * @param {Object.<string, string>} [body] The payload for the API
 * @param {import('https').RequestOptions} options Any additional HTTPS request options
 * @returns {Promise<any>} The parsed JSON response from the server
 */
const request = (url, body, options = { method: 'POST' }) => new Promise((resolve, reject) => {
    /** @type {string | null} */
    let payload = null;

    if (body) {
        payload = JSON.stringify(body);
        options = {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload),
            }
        };
    }

    const request = https.request(url, options, response => {
        let data = '';
        response.setEncoding('utf-8');
        response.on('data', chunk => data += chunk);
        response.on('close', () => {
            const json = JSON.parse(data);
            if (json.status == 'SUCCESS') resolve(json);
            else if (json.message) reject(json.message);
            else reject(json);
        });
    }).on('error', () => reject());

    if (payload) request.write(payload);
    request.end();
});


// Main
(async () => {

    // Read config from JSON
    // ------------------------------------------

    /** @type {PorkbunConfig} */
    const config = await fs.readFile(path.resolve(__dirname, CONFIG_FILE))
        .then(buff => buff.toString())
        .then(json => JSON.parse(json));

    // Pull out the domain and subdomain, leaving just authentication config
    // ------------------------------------------

    const { domain, subdomain } = config;
    delete config.domain;
    delete config.subdomain;

    let resultMessage = '';
    try {
        // Get our own IP address and all existing records
        // ------------------------------------------

        /** @type {string} */
        const ourIp = (await request(`${API_URL}/ping`, config)).yourIp;

        /** @type {PorkbunDNSRecord[]} */
        const allRecords = (await request(`${API_URL}/dns/retrieve/${domain}`, config)).records;

        // Check if our current IP address is already up there or we're in force-mode
        // ------------------------------------------

        const alreadyExists = allRecords.some(record => record.content == ourIp);
        const forceMode = process.argv.some(arg => arg == '-f' || arg == '--force');

        if (!alreadyExists || forceMode) {

            if (forceMode) resultMessage += '(FORCED) ';

            // Look and see if one already exists
            // ------------------------------------------

            const existing = allRecords.filter(({ name, type }) => {
                const n = name == `${subdomain}.${domain}`;
                const t = type == 'A' || type == 'ALIAS';
                return n && t;
            });

            // Remove the old records
            // ------------------------------------------

            const replaced = await Promise.all(existing.map(async record => {
                const endpoint = `${API_URL}/dns/delete/${domain}/${record.id}`;
                await request(endpoint, config);
                return record.content;
            }));

            if (replaced.length)
                resultMessage += `Replaced ${replaced.join(', ')} with ${ourIp}`;
            else
                resultMessage += `Created new DNS record with content ${ourIp}`;

            await request(`${API_URL}/dns/create/${domain}`, {
                ...config,
                name: subdomain,
                type: 'A',
                content: ourIp,
                ttl: 600,
            });

        } else {
            resultMessage = 'Nothing to do.';
        }

    } catch (err) {
        resultMessage = err || 'Something went wrong.';
        process.exitCode = 1;
    } finally {
        console.log(resultMessage);

        // Write to log file
        // ------------------------------------------

        let logHandle;

        try {
            logHandle = await fs.open(LOG_FILE, 'r+');
        } catch (err) {
            if (err.code == 'ENOENT')
                logHandle = await fs.open(LOG_FILE, 'w+');
            else
                throw err;
        }

        const lines = await logHandle.readFile({ encoding: 'utf-8' })
            .then(contents => contents.split(EOL))                      // split on \r?\n
            .then(lines => lines.filter(line => !/^\s*$/.test(line)))   // remove blanks
            .then(lines => lines.slice(0, LOG_SIZE - 1));               // keep only last N-1

        lines.push(`[${new Date().toISOString()}] ${resultMessage}`);   // add the newest (N'th) log
        const payload = Buffer.from(lines.join(EOL) + EOL);

        await logHandle.truncate(0);
        await logHandle.write(payload, 0, payload.byteLength, 0);
        await logHandle.close();
    }
})();
