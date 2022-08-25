#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from os import remove
from sys import stdout, stderr
from glob import glob, escape
from shutil import copytree, rmtree
from os.path import join, dirname, basename, splitext
from subprocess import run

from typing import Iterable


def main(out_type: str, src_dirs: Iterable[str], overwrite: bool = False, verbose: bool = False) -> int:
    """
    Recursively convert a directory of FLAC files to either MP3 or AIFF to be imported into iTunes.

    This script duplicates the target directories before converting their contents (the original
    files are untouched).

    :param str out_type:            The to convert FLAC into, either MP3 or AIFF.
    :param Iterable[str] src_dirs:  One or more directories to clone and convert.
    :param bool overwrite:          Whether or not output directories should be overwritten if they already exist.
    :param bool verbose:            If FFMpeg's stdout (technically, stderr) should be visible.
    :rtype:                         int
    :return:                        A status code; 0 for success, 1 for failure
    """

    # Strip trailing slashes, which can confuse glob
    src_dirs = [ s.rstrip('\\/') for s in src_dirs ]
    out_dirs = [ join(dirname(d), f"[{out_type.upper()}] {basename(d)}") for d in src_dirs ]

    for src, out in zip(src_dirs, out_dirs):
        print(f"\nCopying \"{src}\" to \"{out}\"")

        # Copy the whole thing
        done = False
        while not done:
            try:
                copytree(src, out)
                done = True
            except FileExistsError:
                file = stdout if overwrite else stderr
                print(f"    \"{out}\" already exists", file=file)

                if overwrite:
                    try:
                        rmtree(out)
                    except PermissionError as err:
                        print(err.strerror, file=stderr)
                        print("\nMaybe try it again?")
                        return 1
                else:
                    print("\nRefusing to overwrite output directory without overwrite flag.", file=stderr)
                    return 1
        del done

        print("\nSearching copied directory for *.flac files...")

        flac_files = glob(f"{escape(out)}/**/*.flac", recursive=True)
        dest_files = [ f"{splitext(f)[0]}.{out_type.lower()}" for f in flac_files ]

        # Determine what options to pass to FFMpeg
        options = [ ]
        if out_type == 'aiff':
            options += [ '-write_id3v2', '1', '-c:a', 'pcm_s16be' ]
        elif out_type == 'mp3':
            options += [ '-ab', '320k', '-c:a', 'mp3' ]

        print("\nConverting *.flac files, using the command:")
        print(f"ffmpeg -i ... {' '.join(options)} -c:v copy ...\n")

        # Call FFMpeg
        for flac, dest in zip(flac_files, dest_files):
            print(f"    Converting {flac}")

            command = [ 'ffmpeg', '-i', flac, *options, '-c:v', 'copy', dest ]
            if not verbose:
                command += [ '-loglevel', 'error' ]
            if overwrite:
                command += [ '-y' ]

            run(command)

        print("\nRemoving source *.flac files from copied directory...\n")

        for flac in flac_files:
            print(f"    Removing {flac}")
            remove(flac)

    return 0


if __name__ == '__main__':

    from os import linesep
    from argparse import ArgumentParser, RawDescriptionHelpFormatter

    # Generate description text by stripping main's doc-string
    description = ( line.lstrip() for line in main.__doc__.splitlines() )
    description = ( line for line in description if not line.strip().startswith(':') )
    description = linesep.join(description).strip()

    parser = ArgumentParser(
        prog="flac-exchange",
        description=description,
        formatter_class=RawDescriptionHelpFormatter
    )

    parser.add_argument(
        'format',
        choices=[ 'mp3', 'aiff' ],
        type=str,
        help="the format to convert the FLAC to"
    )

    parser.add_argument(
        'dirs',
        nargs='+',
        type=str,
        help="the folder(s) in which to find FLAC files"
    )

    parser.add_argument(
        '-o',
        '--overwrite',
        action='store_true',
        required=False,
        help="overwrite the output directories if they already exist"
    )

    parser.add_argument(
        '-v',
        '--verbose',
        action='store_true',
        required=False,
        help="show FFMPEG's stdout"
    )

    args = parser.parse_args()
    code = main(args.format, args.dirs, args.overwrite, args.verbose)

    if not code:
        print("\nDone!")
