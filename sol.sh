#!/usr/bin/env bash

usage() {
    echo "nothing yet"
    exit 1
}

# $1 host
connect() {
#    echo "ipmitool -C 17 -I lanplus -H $1 -U root -P 0penBmc sol activate"
    eval "ipmitool -C 17 -I lanplus -H $1 -U root -P 0penBmc -e '#' sol activate"
#    while [[ 1 ]] ; do
#	sleep 1;
#    done
}

end() {
    ipmitool -C 17 -I lanplus -H $1 -U root -P 0penBmc -e '#' sol deactivate
}

exit_sol() {
    stty intr ^c
    exit 1
}

TEMP=$(getopt -o 'h' -l 'help','connect','host:','end'  -n'sol.sh' -- "$@")

if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

echo "$@ ${#@}"

HOST="congo-0337.amd.com"

trap exit_sol SIGINT

if (( ${#@} == 1 )) ; then
    echo "no parameters"
    usage
fi

while true; do
    case "$1" in
	'-h' | '--help') usage;;
	'--connect') connect $HOST; exit 0;;
	'--host') HOST=$2; shift 2; continue;;
	'--end') end $HOST; exit 0;;
	'--') shift; break;;
	* ) echo "unsupported option $(expr substr $1 2 1) ignored";
	    exit 1;;
    esac

done


