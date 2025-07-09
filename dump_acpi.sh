#!/usr/bin/env bash

SEARCH=""

TEMP=$(getopt -o 's:h' -l 'help, search:' -n'dump_acpi.sh' -- "$@")

if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while (( $# > 0 )); do
    case "$1" in
	'-h' | '--help' ) echo "--search show this string in acpi tables"
	       exit 0;;
	'--search') SEARCH=$2
		    shift 2
		    continue
		    ;;
	'--')
	    shift
	    break
	    ;;
	*) exit
	   ;;
    esac
done
acpidump -b
iasl -d *.dat
for file in *.dsl; do
    cat $file | grep -in $SEARCH;
done
