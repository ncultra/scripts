#!/bin/bash

usage() {
    echo "$0 -- a utility to help configure kernel builds"
    echo "$0 --old=<file> copy an existing config file into a new .config"
    echo "$0 --kbuild=<dir> set kernel build directory (if not pwd)"
    echo "$0 --local=<string> add a local version string to the .config in \$kbuild"
}

OLD_CONF=""
KBUILD=""
LOCAL_CONF_STRING=""

copy_conf() {

#save the current .config if it exists
    if [ -f .config ] ; then
	APPEND=$(ls -lgo --time-style=+%Y-%h-%m-%s .config | column -t | cut -d ' ' -f7)
	cp .config .config.$APPEND
    fi
 
    cp $1 .config
# generate a new .config using all defaults for new options
    yes '' | make olddefconfig &>/dev/null

}

change_local_conf() {
    cat .config | sed "s/CONFIG_LOCALVERSION=.*$/CONFIG_LOCALVERSION=\"$LOCAL_CONF_STRING\"/" > .config.tmp
    cp .config.tmp .config
    cat .config | grep "^CONFIG_LOCALVERSION=.*$"
}

if [ $# -lt 1 ] ; then
    usage
fi

until [ -z "$1" ]; do    
    case "${1:0:2}" in
        "--")
        case "${1:2:3}" in 
            "old") OLD_CONF="${1##--old=}";;
            "kbu") KBUILD="${1##--kbuild=}";;
	    "loc") LOCAL_CONF_STRING="${1##--local=}";;
	    "hel") usage;;
        esac ;;
	*)usage;;
    esac
        shift;
done

if [ ${#KBUILD} -gt 0 ] ; then
    pushd $KBUILD
fi

if [ ${#OLD_CONF} -gt 0 ] ; then
    copy_conf $OLD_CONF
fi

if [ ${#LOCAL_CONF_STRING} -gt 0 ] ; then 
    change_local_conf $LOCAL_CONF_STRING
fi

if [ ${#KBUILD} -gt 0 ] ; then
    popd
fi
