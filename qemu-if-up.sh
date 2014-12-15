#!/usr/bin/bash

IFACE=$1
SWITCH=br-tun

IP=$(ip addr show dev $IFACE | grep -v inet6 | grep inet | awk '{print $2}')
NETWORK=$(ip -o route  | grep $IFACE | grep -v default | awk '{print $1}')
GATEWAY=$( ip -o route | grep default | grep proto | awk '{print $3}')

if_up() {
    tunctl -u `whoami` -t $IFACE
    ip link set dev br-tun up
    ip link set dev $IFACE up    
    sleep 0.5s
    brctl addif $SWITCH $IFACE
    echo "$IFACE linked to $SWITCH" 

    exit 0
}


if_down() {

    ip link set dev $IFACE down
    ip link del $TAP_DEVICE
    ip link set dev $SWITCH down
    exit 0
}

if expr match $0 '\(.*ifup\)' &>/dev/null ; then
    if_up
fi

if expr match $0 '\(.*ifdown\)' &>/dev/null ; then
    if_down
fi 




#    ip link add link $IFACE name $TAP_DEVICE type macvtap mode bridge
#    ip link set dev $TAP_DEVICE up
#    ip link add link $TAP_DEVICE br-tun type bridge
#    ip route add $NETWORK dev $TAP_DEVICE metric 0
#    ip route add default via $GATEWAY

#    local TAP_DEVICE=$(ip link show | grep tap | awk '{print $2}')

#    TAP_DEVICE=$(expr $TAP_DEVICE : '\(tap[0-9]\{1,5\}\)')
