#!/usr/bin/env bash

# device
setup() {

    echo To program: sudo ./KSB-B0-dbg-2402/ksb.sh source run_com_unified.tcl
    echo To reload everything: sudo rmmod vfio_pci vfio_pci_core vfio iommufd kvm_amd kvm ccp tsm ide
    sudo modprobe ccp
    sudo modprobe tmpm
    sudo modprobe kvm_amd
    set -x
    sync
    sudo dmesg -n 8
    sudo echo 0 > /sys/module/doe/parameters/delay
    sudo modprobe tsm # Do not normally need this unless rmmod'd
    sudo modprobe ksb_pci_drv

#    sudo  echo 1 > /sys/bus/pci/devices/"${V_FUNCS}"/sriov_numvfs

    sudo  echo "RUN: Selective stream 0" > /dev/kmsg

    #sudo  echo 1 > /sys/bus/pci/devices/"${1}"/tsm_pci_tc_mask

    #sudo  echo 1 > /sys/bus/pci/devices/"${1}"/tsm_tc_mask

    # cert_slot must be 0 for now
    sudo  echo 0 > /sys/bus/pci/devices/"${1}"/tsm_dev/tsm_cert_slot
    cat /sys/bus/pci/devices/"${1}"/tsm_dev/tsm_cert_slot
#    sudo  echo 2 > /sys/bus/pci/devices/"${1}"/tsm_dev/tsm_dev_connect
    cat /sys/bus/pci/devices/"${1}"/tsm_dev/tsm_dev_connect
    sudo  echo "RUN: DEV_CONNECT done" > /dev/kmsg
    sudo  echo 1 > /sys/module/kvm/parameters/gmem_2m_enabled
    cat /sys/module/kvm/parameters/gmem_2m_enabled
}

# $1 device_number
__bind() {
    pushd $TARGET &>/dev/null
    set -x
    sudo modprobe vfio_pci
    sudo echo ""${1}"" > /sys/bus/pci/devices/"${1}"/driver/unbind
    sudo echo vfio-pci > /sys/bus/pci/devices/"${1}"/driver_override
    sudo echo ""${1}"" > /sys/bus/pci/drivers/vfio-pci/bind
    sudo echo '' > /sys/bus/pci/devices/"${1}"/driver_override
    sleep 1
    sudo chown amd:amd /dev/vfio/* /dev/vfio/vfio* /dev/iommu
    popd &>/dev/null
}

build_cmdline() {

    parse_device $T_DEV
    add_opts "$QEMU_EXE "

    add_opts "-L $TARGET/qemu/build/qemu-bundle/usr/local/share/qemu/ "
    add_opts "-L $TARGET "

#    add_opts "-kernel $KERNEL_FILE"
#    add_opts "-append \"$APPEND_KCMD_LINE\""
    add_opts "-enable-kvm -smp 1 -netdev user,id=USER0,hostfwd=tcp::3333-:22 "
    add_opts "-device virtio-net-pci,id=vnet0,iommu_platform=on,disable-legacy=on,romfile=,netdev=USER0 "
    ####

    add_opts "-machine q35,memory-encryption=sev0,memory-backend=ram1,vmport=off "
    add_opts "-object memory-backend-memfd,id=ram1,size=512M,share=true,prealloc=false "
    add_opts "-device virtio-scsi-pci,id=vscsi0,iommu_platform=true,disable-modern=off,disable-legacy=on,romfile= "
    add_opts "-bios ${BIOS} -cpu EPYC-v4 -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1 "

    add_opts "-device isa-serial,id=isa-serial0,chardev=STDIO0 "
    add_opts "-nographic -vga none  -chardev stdio,id=STDIO0,signal=off,mux=on "
    add_opts "-object iommufd,id=i0 "
    #add_opts "-device pcie-root-port,id=r0,slot=0 "
    #-device pcie-root-port,id=r1,slot=1 "
    add_opts "-chardev socket,id=SOCKET0,server=on,wait=off,path=qemu.mon.q.tvm "
    add_opts "-mon chardev=SOCKET0,mode=readline -mon id=MON0,chardev=STDIO0,mode=readline "


    add_opts "-drive id=DRIVE0,if=none,file=${HDA},format=qcow2 ${SNAPSHOT}"
#    add_opts "-device scsi-hd,id=scsi-hd0,drive=DRIVE0 -snapshot "
    add_opts "-device scsi-hd,id=scsi-hd0,drive=DRIVE0 "

    add_opts "-chardev socket,id=SOCKET1,server=on,wait=off,path=qemu.mon.user3333 "
    add_opts "-mon chardev=SOCKET1,mode=control "

#   add_opts "-device vfio-pci,host=${DEVICE}:${FUNCTION}.${VFUNCTION},iommufd=i0,bus=r0"
    add_opts "-device vfio-pci,host=${DEVICE}:${FUNCTION}.${VFUNCTION},iommufd=i0,bus=pcie.0"
#             -device vfio-pci,host=e1:00.0,iommufd=i0,bus=r1

}

start_guest() {

    pushd $TARGET &>/dev/null

    build_cmdline
    # map CTRL-C to CTRL ]
    echo "Mapping CTRL-C to CTRL-]"
    stty intr ^]

    bash ${QEMU_CMDLINE}

    # restore the mapping
    stty intr ^c

    rm -rf ${QEMU_CMDLINE}

    popd &>/dev/null
}

reprogram_xilinx() {

    pushd $TARGET &>/dev/null

    bash -c '(lspci | grep Xilinx) || ( ./KSB-B0-dbg-240619/ksb.sh -interactive  source run_com_unified.tcl ; reboot  )'

    popd &>/dev/null
}


# Note: hotplug is should not be used with the tsm branch
# $1 T_DEV
#hotplug() {
#    NUM=$(echo "${1}" | sed -re 's/[^\.]+\.([0-9]+)/\1/g')
#    ssh -p 3333 amd@localhost 'sudo dmesg -n 8' #lower kernel log level on console
#    echo -e device_add vfio-pci,host=$1,bus=r$NUM,id=v$NUM,iommufd=i0 | nc -q 0  -U ./qemu.mon.q.tvm
#}

add_opts() {
	echo -n "$* " >> ${QEMU_CMDLINE}
}

# $1 T_DEV
parse_device () {
    BUS=$(echo "$1" | sed -E 's/([[:xdigit:]]{4})\:([[:xdigit:]]{2})\:([[:xdigit:]]{2})\.([[:xdigit:]]?)/\1/g')
    DEVICE=$(echo "$1" | sed -E 's/([[:xdigit:]]{4})\:([[:xdigit:]]{2})\:([[:xdigit:]]{2})\.([[:xdigit:]]?)/\2/g')
    FUNCTION=$(echo "$1" | sed -E 's/([[:xdigit:]]{4})\:([[:xdigit:]]{2})\:([[:xdigit:]]{2})\.([[:xdigit:]]?)/\3/g')
    VFUNCTION=$(echo "$1" | sed -E 's/([[:xdigit:]]{4})\:([[:xdigit:]]{2})\:([[:xdigit:]]{2})\.([[:xdigit:]]?)/\4/g')
    echo "$BUS $DEVICE $FUNCTION $VFUNCTION"
}

TARGET="/home/mdday/src"
HDA="u2204_128G_tsm_0.80.qcow2"
QEMU_EXE="./qemu-system-x86_64.tsm"
BIOS="OVMF.fd.tsm"
KERNEL_FILE="/boot/vmlinuz-$(uname -r)"
APPEND_KCMD_LINE="root=UUID=2e220180-8789-487a-8016-52fdeb59554b ro debug loglevel=8 console=ttyS0 earlyprintk=serial accept_memory=eager"

T_DEV="0000:e1:00.0"
BUS=0
DEVICE=0
FUNCTION=0
VFUNCTION=0
V_FUNCS=4
V_DEV=4
SNAPSHOT=""

QEMU_CMDLINE=/tmp/cmdline.$$
rm -rf $QEMU_CMDLINE

TEMP=$(getopt -o 'h' -l 'help','target:','drive:','bios:','show-defaults','show-cmdline','device:','setup','bind','vfuncs:','hotplug','qemu:','test:','reprogram','snapshot' -n'qemu-launch.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true; do
    case "$1" in
	'-h' | '--help') echo "--target <dir> set the base dir for running script";
			 echo "--drive <file> the qcow2 file to use as a ro drive";
			 echo "--bios <file> the OVMF BIOS file to use";
			 echo "--qemu <file> QEMU exe to use";
			 echo "--device <domain:bus:device.function> (trusted device)";
			 echo "--vfuncs <num> set the number of virtual functions for device";
			 echo "--show-defaults show the default values for parameters";
			 echo "--show-cmdline show the QEMU command"
			 echo "--setup configure device (set by --device)for TIO";
			 echo "--bind bind device to vfio (device set by --device)";
			 echo "--snapshot mount the guest image as a with snapshot partition";
#			 echo "--hotplug plug trusted device into guest"
			 exit 0;;
	'--target') TARGET=$2; shift 2; continue;;
	'--drive') HDA=$2; shift 2; continue;;
	'--bios') BIOS=$2; shift 2; continue;;
	'--device') T_DEV=$2; shift 2; continue;;
	'--vfuncs') V_FUNCS=$2; shift 2; continue;;
	'--show-cmdline') build_cmdline; cat $QEMU_CMDLINE; echo"";
			  rm -rf ${QEMU_CMDLINE}; exit 0;;
	'--show-defaults') echo "target dir: $TARGET";
			   echo "drive file: $HDA";
			   echo "bios file: $BIOS";
			   echo "device: $T_DEV";
			   echo "virtual functions $V_FUNCS"
			   echo "qemu $QEMU_EXE"
			   exit 0;;
	'--setup') setup ${T_DEV}; exit 0;;
	'--bind') __bind ${T_DEV}; exit 0;;
	'--snapshot') SNAPSHOT="-snapshot"; shift; continue;;
#	'--hotplug') hotplug ${T_DEV}; exit 0;;
	'--test') V_DEV=$2; test $T_DEV $V_DEV; exit 0;;
	'--reprogram') reprogram_xilinx; exit 0;;
	'--qemu') QEMU_EXE=$2; shift 2; continue;;
	'--') shift; break;;
	* ) echo "unsupported option $(expr substr $1 2 1) ignored";
	    exit 1;;
    esac

done

start_guest
echo ""

