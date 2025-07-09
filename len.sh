#! /usr/bin/env bash

UNAME=`uname -r`
LEN=${#UNAME}
echo "$LEN"
echo $(uname -r | cut -b -10)
ls /boot/*$(uname -r | cut -b -10)*

FILE="foo-bar"

if [[ -e $FILE ]] ; then
    echo "$FILE exists"
fi


if [[ ! -e $FILE ]] ; then
    echo "$FILE does not exist"
fi
