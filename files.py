#! /usr/bin/env python3

import subprocess, string, re, argparse, sys

"""
requires execution from within a git repository.
prefers a configuration that is capable of executing ssh commands
on the target with a public key (no login: prompt)
"""

def cp_status(args):
    """
    Inspects the status of a git repository and copies modified files
    to the target host:directory
    """
    f = re.compile(b'modified:')
    files = subprocess.run(["git", args.get('type')[0]], capture_output= True)
    for file in files.stdout.splitlines():
        if f.search(file) is not None:
            source_string = file.rpartition(b'modified:')[2].rstrip().lstrip().decode("utf-8")
            target_string = args.get('target')[0] + "/" + source_string
            subprocess.run(["scp", source_string, target_string])

def cp_patch(args):
    """
    Inspects a git patch object and copies the files to the target host:directory.
    The ".c" regexp can match any line with a ".com" email address in it.
    To not save those lines as a filename, disqualify them if they also match
    any of the "-by: tags that are present in linux patches.
    """
    f = re.compile(b'\.[ch]{1} | \.S | \.rst | \.txt | \.sh | \.py \
                   | Makefile | Kconfig | \.config')
    t = re.compile(b'author: | -by:', re.I)
    files = subprocess.run(["git", "show", "--stat", args.get('object')[0]], capture_output=True)
    for file in files.stdout.splitlines():
        if f.search(file) is not None and t.search(file) is None :
            source_string = file.rpartition(b'| ')[0].rstrip().lstrip().decode("utf-8")
            target_string = args.get('target')[0] + "/" + source_string
            subprocess.run(["scp", source_string, target_string])

def files_main(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('--target', action = 'store', nargs = 1, \
                        help = 'target host and root directory')
    parser.add_argument('--type', action = 'store', nargs = 1, \
                        help = 'patch or status')
    parser.add_argument('--object', action = 'store', nargs = 1, \
                        help = 'git object to inspect for files')
    vargs = vars(parser.parse_args())
    if "patch" in vargs.get('type')[0]:
        cp_patch(vargs)
    if "status" in vargs.get('type')[0]:
        cp_status(vargs)

if __name__ == "__main__":
    files_main(sys.argv)
    sys.exit(0)
