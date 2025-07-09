#!/usr/bin/env bash

CLEAN=0
INSTALL=0
DMA_MIGRATION=0
TMPM=0
TARGET="$(pwd)"
TEST=0
PMIO=0
CONFIG=0
REPLACE=0
OVMF=0
OVMF_BRANCH="master"
OVMF_GIT_URL="https://github.com/tianocore/edk2.git"
QEMU=0
QEMU_GIT_URL="https://github.com/AMDESE/qemu.git"
QEMU_BRANCH="snp-latest"

SNP_LINUX=0
KERNEL_GIT_URL="https://github.com/AMDESE/linux.git"
KERNEL_HOST_BRANCH="snp-host-latest"
SNP_LINUX_BUILD="host"

ID_LIKE="debian"
PACKAGE=0

TEMP=$(getopt -o 'cidth' -l 'package','target:','pmio','test','config','replace','ovmf','qemu','snp-linux','help' -n'rebuild.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true ; do
    case "$1" in
	'-c' ) CLEAN=1; shift; continue;;
	'-i' ) INSTALL=1; shift;
	       if (( $EUID != 0 )) ; then
		   echo "installation must be run as root"
		   exit 1
	       fi
	       continue;;
	'-d' ) DMA_MIGRATION=1;shift; continue;;
	'-t' ) TMPM=1; shift; continue;;
	'-h' | '--help' ) echo "-c clean";
	       echo "-i install";
	       echo "-d set CONFIG_DMA_MIGRATION";
	       echo "-t build TMPM as a module";
	       echo "--target set build directory (default current dir)";
	       echo "--test link in test library";
	       echo "--pmio build and link PAGE_MOVE_IO and IOMMU"
	       echo "--config re-configure kernel build"
	       echo "--replace (requires -i) replace existing kernel boot files"
	       echo "--ovmf build OVMF"
	       echo "--qemu build QEMU"
	       echo "--snp-linux build snp-host-latest"
	       echo "--package build *.debs (kernel)"
	       exit 0;;
	'--target') TARGET=$2; shift 2; continue;;
	'--test' ) TEST=1; shift; continue;;
	'--pmio' ) PMIO=1; shift; continue;;
	'--config' ) CONFIG=1; shift; continue;;
	'--replace' ) REPLACE=1; shift; continue;;
	'--ovmf' ) OVMF=1; shift; continue;;
	'--qemu' ) QEMU=1; shift; continue;;
	'--snp-linux' ) SNP_LINUX=1; shift; continue;;
	'--package' ) PACKAGE=1; shift; continue;;
	'--') shift; break;;
	*  ) echo "unsupported option $(expr substr $1 2 1) ignored";
	     exit 1;;
    esac
done

. ~/bin/common.sh



# save a small number of threads for things other than building the kernel
NPROC=$(( $(nproc) - 12 ))

pushd $TARGET

if (( $SNP_LINUX == 1 )) ; then
    pushd /home/amd/src/ >/dev/null
    build_kernel host
    popd
fi

if (( $QEMU == 1 )) ; then
    pushd /home/amd/src/ >/dev/null

    build_install_qemu /root

    popd
    exit 0
fi

if (( $OVMF == 1)) ; then
    pushd /home/amd/src/ >/dev/null
    build_install_ovmf /home/amd/src/qemu/build/qemu_fw/usr/local/share/qemu/
    popd
    exit 0
fi

if (( $CONFIG == 1 )) ; then
    config_kernel
    config_tmpm

    yes "" | make olddefconfig
fi

if (( $CLEAN == 1 )) ; then
    make clean
fi

make -j $NPROC

if (( $PACKAGE == 1 | $INSTALL == 1 )) ; then

    make -j $NPROC modules
    make -j $NPROC INSTALL_MOD_STRIP=1 modules_install

fi

if (( $PACKAGE == 1 )) ; then
    make deb-pkg
fi

if (( $INSTALL == 1 )) ; then
    if [ ! -d /home/amd/src/config-save ] ; then
	mkdir /home/amd/src/config-save
    fi
    cp -v .config /home/amd/src/config-save/.config"-$(git branch --show-current)-$(date)".bak

    pushd /boot/ &>/dev/null
    if (( $REPLACE == 1 )) ; then
	rm -v *$(uname -r | cut -b -10)*
	rm -v vmlinuz vmlinuz.old
	rm -v initrd.img initrd.img.old
    fi
    grub-install
    popd
    make install
fi
popd
