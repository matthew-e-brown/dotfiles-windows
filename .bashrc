# Get my private environment variables
source ~/.env

# Alias for dotfiles git repo
alias dots='$(which git) --git-dir=$HOME/.dots/ --work-tree=$HOME'

# Function to get what the current IP address of my desktop is
home_ip() {
	if [[ -z "${HOME_IP_GIST}" ]]; then
		echo "Gist URL is not set!" 1>&2
		return 1
	else
		local GIST_URL="https://gist.githubusercontent.com/$HOME_IP_GIST/raw/ip_data.json"
		echo "$(curl "$GIST_URL" 2> /dev/null | jq '.current.address' -r)"
		return 0
	fi
}
