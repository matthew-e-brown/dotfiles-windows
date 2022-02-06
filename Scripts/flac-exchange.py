import sys
import shutil
import subprocess
from os import path, remove
from glob import glob, escape
from argparse import ArgumentParser

prog_desc = """
Recursively convert a directory of FLAC files to either MP3 or AIFF to be
imported into iTunes.\n  
By default, this script duplicates the target directories before converting
their contents (the original files are untouched).
"""

parser = ArgumentParser(prog="flac-exchange", description=prog_desc)

parser.add_argument('format', choices=['mp3', 'aiff'], type=str,
                    help="the format to convert the FLAC to")

parser.add_argument('dirs', nargs='+', type=str,
                    help="the folder(s) in which to find FLAC files")

parser.add_argument('-o', '--overwrite', action='store_true', required=False,
                    help="overwrite the output directories if they already exist")

parser.add_argument('-v', '--verbose', action='store_true', required=False,
                    help="Show FFMPEG's stdout")

args = parser.parse_args()


out_type = args.format
# Cut off trailing slashes that tend to confuse path.basename
src_dirs = [ d[:-1] if d[-1] == '\\' or d[-1] == '/' else d for d in args.dirs ]
# *Sibling* directory of sources with [TYPE] before it
out_dirs = [ path.join(path.dirname(d), f"[{out_type.upper()}] {path.basename(d)}") for d in src_dirs ]

for src, out in zip(src_dirs, out_dirs):
  print(f"\nCopying \"{src}\" to \"{out}\"")

  # Copy the tree
  done = False
  while not done:
    try:
      shutil.copytree(src, out)
      done = True
    except FileExistsError:
      print(f"    \"{out}\" already exists",
            file=sys.stderr if not args.overwrite else sys.stdout)

      # File exists... should we overwrite it?
      if args.overwrite:
        print("    Erasing existing directory")
        try:
          shutil.rmtree(out)
          # Couldn't delete file...
        except PermissionError as err:
          print(err.strerror, file=sys.stderr)
          print("\nSometimes this can happen arbitrarily. Try again.",
                file=sys.stderr)
          sys.exit(1)
        # while loop; retry copying
      else:
        print("    Refusing to overwrite output directory without overwrite flag",
              file=sys.stderr)
        sys.exit(1)
  del done

  # Find the flac files to convert
  print("\nSearching for *.flac files")

  flac_files = glob(f"{escape(out)}/**/*.flac", recursive=True)
  dest_files = [ f"{path.splitext(f)[0]}.{out_type.lower()}" for f in flac_files ]

  # Determine the right options for AIFF or MP3
  options = []
  if out_type == 'aiff': options += [ '-write_id3v2', '1' ]
  elif out_type == 'mp3': options += [ '-ab', '320k' ]

  print("\nConverting *.flac files, using the command:")
  print(f"ffmpeg -i [FLAC] {' '.join(options)} -c:v copy [DEST]\n")

  # Actually do the converting
  for flac, dest in zip(flac_files, dest_files):
    print(f"    Converting {flac}")

    command = [ 'ffmpeg', '-i', flac ] + options + [ '-c:v', 'copy', dest ]
    if not args.verbose: command += [ '-loglevel', 'error' ]

    subprocess.run(command)

  print("\nRemoving source *.flac files\n")

  for flac in flac_files:
    print(f"    Removing {flac}")
    remove(flac)

print("\nDone!")
sys.exit(0)