#!/usr/bin/bash

# need to read from a configuration file
IFACE=wlp3s0

IP=$(ip addr show dev $IFACE | grep -v inet6 | grep inet | awk '{print $2}')
NETWORK=$(ip -o route  | grep $IFACE | grep -v default | awk '{print $1}')
GATEWAY=$( ip -o route | grep default | grep proto | awk '{print $3}')

if_up() {
    echo "called qemu-ifup"
    local TAP_DEVICE=macvtap$RANDOM
    
    ip link add link $IFACE name $TAP_DEVICE type macvtap mode bridge
    ip link set dev $TAP_DEVICE up
    ip route add $NETWORK dev $TAP_DEVICE metric 0
    ip route add default via $GATEWAY

    exit 1
}

if_down() {
    echo "called qemu-ifdown"
    local TAP_DEVICE=$(ip link show | grep macvtap | awk '{print $2}')

    TAP_DEVICE=$(expr $TAP_DEVICE : '\(macvtap[0-9]\{1,5\}\)')
    echo $TAP_DEVICE
    ip link set dev $TAP_DEVICE down
    ip link del $TAP_DEVICE
    exit 1
}


if expr match $0 '\(.*ifup\)' &>/dev/null ; then

#if expr index $0 "ifup" ; then
    if_up
fi

if expr match $0 '\(.*ifdown\)' &>/dev/null ; then
#if expr index $0 "ifdown" ; then
    if_down
fi 

