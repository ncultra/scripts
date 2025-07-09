#!/usr/bin/env bash

LINES=0

TEMP=$(getopt -o 'l:' -l 'lines:' -n'hgrep.sh' -- "$@")

if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while (( $# > 0 )); do
    case "$1" in
	'-l' | '--lines' ) LINES=$2;
			   shift 2;
			   continue;;
	'--' ) shift;
	       break;;
	*) echo 'Internal error!' >&2
	   exit;;
    esac
done

if (( $LINES )); then
   egrep --color=auto "$@" ~/.bash_history | tail -n "$LINES"
#egrep --color=auto $1 ~/.bash_history | tail -n $LINES
#    | egrep --color=auto -v grep
else
    egrep --color=auto $@ ~/.bash_history | egrep --color=auto -v grep
fi
