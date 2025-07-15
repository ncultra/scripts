#! /usr/bin/env bash

set -u

. /home/mdday/bin/common.sh

config_kernel_simple()
{
    LOCAL_VER="$(git branch --show-current | cut -b -30)"

    if [[ ! -e ".config" ]] ; then
	run_cmd "cp /boot/config-$(uname -r) .config"
    fi
    run_cmd ./scripts/config --set-str CONFIG_LOCALVERSION "${LOCAL_VER//\//-}"
    yes "" | make olddefconfig
    config_for_gmem_tlb
    config_bpf
    RESET_OWNER=1
}

build_kernel_simple()
{
    if [[ ! -e ".config" ]]; then
	config_kernel_simple
    fi

    make -j $NPROC

    RESET_OWNER=1
}

clean_kernel()
{
    make clean
}

build_kernel_install()
{
    build_kernel_simple
    make -j $NPROC modules
    make -j $NPROC INSTALL_MOD_STRIP=1 modules_install
    make install
}

[[ $EUID != 0 ]] && echo "must be executed as root" && exit 1

MY_UID="mdday"
RESET_OWNER=0
BPF=0
RESERVE_PROCS=12

# save a small number of threads for things other than building the kernel
NPROC=$(( $(nproc) - $RESERVE_PROCS ))

TEMP=$(getopt -o 'ibch' -l 'bpf','build','clean','config','help','install' -n'build-tsm.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true ; do
    case "$1" in
	'--build' ) shift; build_kernel_simple; continue;;
	'-c' | '--clean' ) shift; clean_kernel; continue;;
	'--config' ) shift; config_kernel_simple; continue;;
	'-i' | '--install' ) shift; build_kernel_install; continue;;
	'-h' | '--help' ) echo "--build rebuild kernel";
			  echo "--clean make clean";
			  echo "--config kernel";
			  echo "--install install kernel";
			  exit 0;;
	'--') shift; break;;
	*  ) echo "unsupported option $(expr substr $1 2 1) ignored";
	     exit 1;;
    esac
done

if [[ $RESET_OWNER != 0 ]]; then
    run_cmd "chown -R $MY_UID:$MY_UID * .*"
fi
