#!/usr/bin/env bash

BUILD_KERNEL=0
RESTART=0
INSTALL_KERNEL=0
BUILD_IOMMU=0
SP5=onyx-762ahost.amd.com
KERNEL_NAME=$(ssh root@$SP5 "uname -r")
USERNAME=amd
#SRCDIR=/home/mdday/src/linux-tmpm/drivers/dma/tmpm/
SRCDIR=/home/mdday/src/linux/mm/
DSTDIR=/home/amd/src/linux-tmpm/mm/
#DSTDIR=/home/amd/src/linux/drivers/dma/tmpm/
LINUXDIR=/home/amd/src/linux-tmpm/
#LINUXDIR=/home/amd/src/linux/
#SRC_TSTDIR=/home/mdday/src/linux-tmpm/tools/testing/selftests/dma/tmpm
#DST_TSTDIR=$LINUXDIR/tools/testing/selftests/dma/tmpm/

function install() {
    ssh root@$SP5 "pushd /boot/grub; cp -v grub.cfg grub.cfg.bak; popd"
    ssh root@$SP5 "pushd /boot/ &>/dev/null; rm -v *-6.*; popd"
    ssh root@$SP5 "pushd /boot/ &>/dev/null; rm -v vmlinuz; rm -v initrd.img; popd"
    ssh root@$SP5 "pushd /boot &>/dev/null; grub-install"
    ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; make install"
    ssh root@$SP5 "pushd /boot/grub &>/dev/null; cp -v grub.cfg.bak grub.cfg"
}

## supported options:
##                    -k build new kernel after changing relevant kernel files
##                    -i install the new kernel
##                    -r restart the server after building or installing new kernel.
##                    -m build iommu
## an embarrasingly stupid options processor. for anything more, replace with getopts
while (( $# > 0 ))
do
    case $(expr substr $1 1 1) in
	'-' )
	      case $(expr substr $1 2 1) in
		  'k' ) BUILD_KERNEL=1;;
		  'r' ) RESTART=1;;
		  'i' ) INSTALL_KERNEL=1;
			install; exit;;
		  'm' ) BUILD_IOMMU=1;;
		  *  ) echo "unsupported option $(expr substr $1 2 1) ignored";
		       exit;;
	      esac
	      ;;
    esac
    shift
done

# delete the driver source files previously there
#ssh root@$SP5 "pushd $DSTDIR &>/dev/null; rm *.h ; rm *.c; popd &>/dev/null"
#ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
pushd $SRCDIR
#scp Makefile $USERNAME@$SP5:$DSTDIR
#scp Kconfig $USERNAME@$SP5:$DSTDIR
#scp *.c $USERNAME@$SP5:$DSTDIR
#scp *.h $USERNAME@$SP5:$DSTDIR
#scp /home/mdday/src/linux/include/linux/migrate_dma.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/

ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
if (( BUILD_KERNEL == 1 )) ; then
    scp /home/mdday/src/linux/include/linux/migrate_dma.h $USERNAME@$SP5:/home/amd/src/linux-tmpm/include/linux/
    scp /home/mdday/src/linux/mm/Makefile $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
    scp /home/mdday/src/linux/mm/migrate_dma.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
    scp /home/mdday/src/linux/mm/Kconfig $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
    scp /home/mdday/src/linux/mm/migrate.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
#    scp /home/mdday/src/linux-tmpm/mm/migrate_device.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
    scp /home/mdday/src/linux/include/linux/migrate.h $USERNAME@$SP5:/home/amd/src/linux-tmpm/include/linux/
    scp /home/mdday/src/linux/mm/util.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/mm/
    scp /home/mdday/src/linux/drivers/misc/migration_offload.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/misc/
    scp /home/mdday/src/linux/drivers/misc/Kconfig $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/misc/
    scp /home/mdday/src/linux/drivers/misc/Makefile $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/misc/
#    scp /home/mdday/src/linux-tmpm/include/linux/amd-iommu.h $USERNAME@$SP5:/home/amd/src/linux-tmpm/include/linux/
#    scp /home/mdday/src/linux-tmpm/include/linux/psp-tmpm.h $USERNAME@$SP5:/home/amd/src/linux-tmpm/include/linux/
#    scp /home/mdday/src/linux-tmpm/drivers/iommu/amd/amd_iommu_types.h $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/iommu/amd/
#    scp /home/mdday/src/linux-tmpm/drivers/iommu/amd/init.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/iommu/amd/
#    scp /home/mdday/src/linux-tmpm/drivers/crypto/ccp/tmpm-dev.c $USERNAME@$SP5:/home/amd/src/linux-tmpm/drivers/crypto/ccp/
fi

popd &>/dev/null
ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; make -j 180; popd &>/dev/null"


## dmesg -wH -n8 &
## ssh root@$SP5 "echo 8 > /proc/sys/kernel/printk"
##  ipmitool  -C 17 -H 10.227.41.216 -I lanplus -P 0penBmc  -U root sol activate
#/**
# * @note: we are using an identity-mapped IOMMU page table, which means
# * we can treat page physical addresses and DMA handles interchangeably. This
# * requires patches to the amd IOMMU driver that are currently in-process.
# *
# * kernel cmdline must include:
# * ivrs_acpihid[C0:00.4]=AMDI0095:0
# * ivrs_acpihid[C0:00.4]=AMDI0095:0
# * also: configure the tmpm device to use the identity2 iommu page table
# *
# * #find /sys | grep iommu_groups | grep AMDI
# * /sys/kernel/iommu_groups/<group>/devices/AMDI0095:00
# * echo "identity2" > /sys/kernel/iommu_groups/<group>/type
# **/
