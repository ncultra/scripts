#!/usr/bin/env bash

export CONTROL=/sys/kernel/debug/dynamic_debug/control
echo $CONTROL
#reset:
echo "module * -p" | sudo tee $CONTROL
echo "file * -p" | sudo tee $CONTROL
#echo "file arch/x86/kvm/* +p" | sudo tee $CONTROL
echo "module kvm_amd +p" | sudo tee $CONTROL
#echo "file mm/restrictedmem.c +p" | sudo tee $CONTROL
echo "module restrictedmem +p" | sudo tee $CONTROL
echo "module debug_vm_pgtable +p" | sudo tee $CONTROL
echo "file mm/migrate.c +p" | sudo tee $CONTROL
echo "file arch/x86/kernel/sev.c +p" | sudo tee $CONTROL
echo "file arch/x86/kvm/svm/sev.c +p" | sudo tee $CONTROL
echo "file arch/x86/kvm/../../../virt/kvm/kvm_main.c +p" | sudo tee $CONTROL
echo "file arch/x86/kvm/mmu/mmu_internal.h +p" | sudo tee $CONTROL
echo "file drivers/crypto/ccp/sev-dev.c +p" | sudo tee $CONTROL
echo "file drivers/crypto/ccp/psp-dev.c +p" | sudo tee $CONTROL
echo "file drivers/crypto/ccp/sp-dev.c +p" | sudo tee $CONTROL
echo "file drivers/crypto/ccp/tee-dev.c +p" | sudo tee $CONTROL
echo "file drivers/crypto/ccp/tmpm-dev.c +p" | sudo tee $CONTROL
echo "file arch/x86/coco/sev/host.c +p" | sudo tee $CONTROL
echo "file virt/kvm/guest_mem.c +p" | sudo tee $CONTROL
echo "file arch/x86/kvm/x86.c +p" | sudo tee $CONTROL
echo "file drivers/dma/tmpm/rbuf.c +p" | sudo tee $CONTROL
echo "file drivers/dma/tmpm/main.c +p" | sudo tee $CONTROL
echo "file virt/kvm/kvm_main.c +p" | sudo tee $CONTROL


exit

drivers/crypto/ccp/ccp-dev-v3.c
drivers/crypto/ccp/ccp-dev-v5.c
drivers/crypto/ccp/ccp-dmaengine.c
drivers/crypto/ccp/ccp-ops.c
drivers/crypto/ccp/psp-dev.c
drivers/crypto/ccp/sev-dev.c
drivers/crypto/ccp/sp-dev.c
drivers/crypto/ccp/sp-pci.c
drivers/crypto/ccp/sp-platform.c
drivers/crypto/ccp/tee-dev.c
drivers/crypto/ccp/tmpm-dev.c


exit
