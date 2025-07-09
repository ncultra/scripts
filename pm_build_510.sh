#!/usr/bin/env bash

BUILD_KERNEL=0
RESTART=0
INSTALL_KERNEL=0
BUILD_IOMMU=0

SP5=onyx-762ahost.amd.com
KERNEL_NAME=$(ssh root@$SP5 "uname -r")
USERNAME=amd
SRCDIR=/home/mdday/src/linux-stable/drivers/dma/tmpm/
DSTDIR=/home/amd/src/linux-stable/drivers/dma/tmpm/
#DSTDIR=/home/amd/src/linux/drivers/dma/tmpm/
LINUXDIR=/home/amd/src/linux-stable/
#LINUXDIR=/home/amd/src/linux/
#SRC_TSTDIR=/home/mdday/src/linux-stable/tools/testing/selftests/dma/tmpm
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
ssh root@$SP5 "pushd $DSTDIR &>/dev/null; rm *.h ; rm *.c; popd &>/dev/null"
ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
pushd $SRCDIR
scp Makefile $USERNAME@$SP5:$DSTDIR
scp Kconfig $USERNAME@$SP5:$DSTDIR
scp *.c $USERNAME@$SP5:$DSTDIR
scp *.h $USERNAME@$SP5:$DSTDIR
scp /home/mdday/src/linux-stable/include/linux/migrate_dma.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/
scp /home/mdday/src/linux-stable/include/linux/iommu.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/
scp /home/mdday/src/linux-stable/include/linux/amd-iommu.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/
scp /home/mdday/src/linux-stable/include/linux/migrate.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/
scp /home/mdday/src/linux-stable/include/linux/psp-tmpm.h $USERNAME@$SP5:/home/amd/src/linux-stable/include/linux/

ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
if (( BUILD_KERNEL == 1 )) ; then
    scp /home/mdday/src/linux-stable/mm/Kconfig $USERNAME@$SP5:/home/amd/src/linux-stable/mm/
    scp /home/mdday/src/linux-stable/mm/Makefile $USERNAME@$SP5:/home/amd/src/linux-stable/mm/
    scp /home/mdday/src/linux-stable/mm/migrate_dma.c $USERNAME@$SP5:/home/amd/src/linux-stable/mm/
    scp /home/mdday/src/linux-stable/mm/migrate.c $USERNAME@$SP5:/home/amd/src/linux-stable/mm/
    scp /home/mdday/src/linux-stable/mm/util.c $USERNAME@$SP5:/home/amd/src/linux-stable/mm/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/amd_iommu.h $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/amd_iommu_types.h $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/debugfs.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/init.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/io_pgtable.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/amd/iommu.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/amd/
    scp /home/mdday/src/linux-stable/drivers/iommu/dma-iommu.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/
    scp /home/mdday/src/linux-stable/drivers/iommu/iommu.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/
    scp /home/mdday/src/linux-stable/drivers/iommu/iommu.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/iommu/

    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/Makefile $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/psp-dev.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/psp-dev.h $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/sp-dev.h $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/sp-pci.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/tmpm-dev.c $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/
    scp /home/mdday/src/linux-stable/drivers/crypto/ccp/tmpm-dev.h $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/crypto/ccp/

    scp /home/mdday/src/linux-stable/drivers/dma/Kconfig $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/dma/
    scp /home/mdday/src/linux-stable/drivers/dma/Makefile $USERNAME@$SP5:/home/amd/src/linux-stable/drivers/dma/

fi


ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; chown -R amd:amd ./*; popd &>/dev/null"
ssh root@$SP5 "pushd $LINUXDIR &>/dev/null; /root/bin/rebuild-510.sh; popd &>/dev/null"


