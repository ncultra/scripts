#!/usr/bin/env bash

BUILD_KERNEL=0
RESTART=0
BUILD_IOMMU=0
COPY_KERNEL=0

SP5=""
#onyx-762ahost.amd.com
#SP5=10.217.81.122

USERNAME=root
DSTDIR=/drivers/dma/tmpm/
SRC_TSTDIR=/tools/testing/selftests/dma/tmpm/
DST_TSTDIR=/tools/testing/selftests/dma/tmpm/

TARGET=""
TARGET_DIR="linux/drivers/dma/tmpm/"
SOURCE=""

TEMP=$(getopt -o 'kmchd:' -l 'target:,source:,target-host:' -n'pm_build.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while (( $# > 0 )); do
    case "$1" in
    	'-k') BUILD_KERNEL=1;
	      shift
	      continue
	      ;;
	'-m') BUILD_IOMMU=1;
	      shift
	      continue
	      ;;
	'-c') COPY_KERNEL=1; BUILD_KERNEL=0;
	      shift
	      continue
	      ;;
	'--target') TARGET=$2;
	      shift 2
	      continue
	      ;;
	'--source') SOURCE=$2;
		    shift 2
		    continue
		    ;;
	'--target-host') SP5=$2; echo "target host $SP5"
			 shift 2
			 continue
			 ;;
	'-h') echo "-k build kernel";
	      echo "-m include iommu files";
	      echo "-c copy kernel files to target host";
	      echo "--target-host the hostname of the build target"
	      echo "--target the target root linux directory to build"
	      echo "--source the source root linux directory"
 	      exit 0;;
	'--')
	    shift
	    break
	    ;;
	*) echo 'Internal error!' >&2
	    exit;;
    esac
done
echo "$(ssh root@$SP5 "uname -r")"
NPROC=$(( $(ssh root@$SP5 "nproc") - 10 ))
echo "$NPROC"

# delete the driver source files previously there
ssh root@$SP5 "pushd $TARGET/$DSTDIR &>/dev/null; rm -v *.h ; rm *.c; popd &>/dev/null"
ssh root@$SP5 "pushd $TARGET/$DSTDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
pushd $SOURCE$DSTDIR
pwd
scp Makefile $USERNAME@$SP5:$TARGET/$DSTDIR
scp Kconfig $USERNAME@$SP5:$TARGET/$DSTDIR
scp *.c $USERNAME@$SP5:$TARGET/$DSTDIR
scp *.h $USERNAME@$SP5:$TARGET/$DSTDIR
scp $SOURCE/include/linux/migrate_dma.h $USERNAME@$SP5:$TARGET/include/linux/

ssh root@$SP5 "pushd $TARGET &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
if (( BUILD_KERNEL == 1 || COPY_KERNEL == 1)) ; then
    scp $SOURCE/include/linux/migrate_dma.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/include/linux/mm.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/mm/Makefile $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/migrate_dma.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/Kconfig $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/migrate.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/util.c $USERNAME@$SP5:$TARGET/mm/
    #    scp $SOURCE/mm/migrate_device.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/mempolicy.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/shmem.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/include/linux/migrate.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/mm/util.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/mm/huge_memory.c $USERNAME@$SP5:$TARGET/mm/
    scp $SOURCE/include/linux/amd-iommu.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/include/linux/psp-tmpm.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/drivers/iommu/amd/amd_iommu_types.h $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/fs/aio.c $USERNAME@$SP5:$TARGET/fs/
    scp $SOURCE/fs/hugetlbfs/inode.c $USERNAME@$SP5:$TARGET/fs/hugetlbfs/
    scp $SOURCE/drivers/misc/migration_offload.c $USERNAME@$SP5:$TARGET/drivers/misc/
    scp $SOURCE/drivers/misc/Kconfig $USERNAME@$SP5:$TARGET/drivers/misc/
    scp $SOURCE/drivers/misc/Makefile $USERNAME@$SP5:$TARGET/drivers/misc/
    scp $SOURCE/drivers/iommu/amd/init.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/crypto/ccp/tmpm-dev.c $USERNAME@$SP5:$TARGET/drivers/crypto/ccp/
    scp $SOURCE/arch/x86/kvm/x86.c $USERNAME@$SP5:$TARGET/arch/x86/kvm/
    scp $SOURCE/arch/x86/virt/svm/sev.c $USERNAME@$SP5:$TARGET/arch/x86/virt/svm/
    scp $SOURCE/arch/x86/kvm/svm/svm.c $USERNAME@$SP5:$TARGET/arch/x86/kvm/svm/
    scp $SOURCE/arch/x86/include/asm/sev.h $USERNAME@$SP5:$TARGET/arch/x86/include/asm/
    scp $SOURCE/arch/x86/include/asm/svm.h $USERNAME@$SP5:$TARGET/arch/x86/include/asm/
    scp $SOURCE/drivers/crypto/ccp/sev-dev.c $USERNAME@$SP5:$TARGET/drivers/crypto/ccp/
    scp $SOURCE/arch/x86/include/asm/sev-host.h $USERNAME@$SP5:$TARGET/arch/x86/include/asm/
    scp $SOURCE/virt/kvm/guest_mem.c $USERNAME@$SP5:$TARGET/virt/kvm
    scp $SOURCE/arch/x86/virt/svm/sev.c $USERNAME@$SP5:$TARGET/arch/x86/virt/svm/
fi

if (( BUILD_IOMMU == 1 || COPY_KERNEL == 1)) ; then
    scp $SOURCE/drivers/iommu/amd/init.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/Documentation/admin-guide/kernel-parameters.txt $USERNAME@$SP5:$TARGET/Documentation/admin-guide/
    scp $SOURCE/drivers/iommu/amd/amd_iommu.h $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/amd/iommu.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/amd/amd_iommu_types.h $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/amd/debugfs.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/amd/init.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/amd/io_pgtable.c $USERNAME@$SP5:$TARGET/drivers/iommu/amd/
    scp $SOURCE/drivers/iommu/dma-iommu.c $USERNAME@$SP5:$TARGET/drivers/iommu/
    scp $SOURCE/drivers/iommu/iommu.c $USERNAME@$SP5:$TARGET/drivers/iommu/
    scp $SOURCE/include/linux/iommu.h $USERNAME@$SP5:$TARGET/include/linux/
    scp $SOURCE/include/uapi/linux/iommu.h $USERNAME@$SP5:$TARGET/include/uapi/linux/
fi

if (( COPY_KERNEL == 0 )); then
    ssh root@$SP5 "pushd $TARGET &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
    ssh root@$SP5 "pushd $TARGET &>/dev/null; make -j $NPROC; popd &>/dev/null"
    pushd $SOURCE/$SRC_TSTDIR
    scp Makefile $USERNAME@$SP5:$TARGET/$DST_TSTDIR
    scp *.c  $USERNAME@$SP5:$TARGET/$DST_TSTDIR
    ssh root@$SP5 "pushd $TARGET/$DST_TSTDIR &>/dev/null; make; popd&>/dev/null"
    popd &>/dev/null
fi
popd &>/dev/null

if (( RESTART == 1 )) ; then
    ssh root@$SP5 "shutdown -r now"
fi

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
