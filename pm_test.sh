#!/usr/bin/env bash

USERNAME=amd
MODNAME=tmpm.ko
SRCDIR=/home/amd/src/pm-mpdma-driver
pushd $SRCDIR

make clean
make
sudo dmesg -C &>/dev/null
sudo insmod $MODNAME &>/dev/null
dmesg
sudo dmesg -C &>/dev/null
sudo rmmod $MODNAME &>/dev/null
dmesg
popd
