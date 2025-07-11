
#!/bin/bash

clear_trace()
{
    echo "" > "$TRACING_DIR"/trace;
}

stop_trace()
{
    echo 0 > "$TRACING_DIR"/tracing_on
}

# stack_trace $1 symbol $2 pid
stack_trace()
{
    pushd "$TRACING_DIR" &>/dev/null;
    echo 0 > tracing_on
    echo "function_graph" > current_tracer
#    echo "$MAX_STACK_DEPTH" > max_graph_depth
    echo "$1" > set_graph_function
    echo "$2" > set_ftrace_pid
    echo 1 > tracing_on
    popd &>/dev/null
}

# full_stack_trace $1 symbol $2 pid
full_stack_trace()
{
    pushd "$TRACING_DIR" &>/dev/null;

    echo "function" > current_tracer
    echo 1 > options/func_stack_trace
    echo "$1" > set_ftrace_filter
    echo "$2" > set_ftrace_pid
    echo 1 > tracing_on
    popd &>/dev/null
}

run_cmd()
{
	echo "$*"

	eval "$*" || {
		echo "ERROR: $*"
		exit 1
	}
}

config_bpf()
{
    run_cmd ./scripts/config --enable CONFIG_BPF
    run_cmd ./scripts/config --enable CONFIG_BPF_SYSCALL
    run_cmd ./scripts/config --enable CONFIG_BPF_JIT
    run_cmd ./scripts/config --enable HAVE_EBPF_JIT
    run_cmd ./scripts/config --enable ARCH_WANT_DEFAULT_BPF_JIT
    run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO_BTF
    run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO_BTF_MODULES

    run_cmd ./scripts/config --enable CONFIG_UPROBES
    run_cmd ./scripts/config --enable CONFIG_UPROBE_EVENTS
    run_cmd ./scripts/config --enable CONFIG_FTRACE
    run_cmd ./scripts/config --enable CONFIG_TRACING
    run_cmd ./scripts/config --enable CONFIG_FTRACE_SYSCALLS

}

config_tmpm()
{
    run_cmd ./scripts/config --enable CONFIG_NUMA_EMU

    run_cmd ./scripts/config --enable TRANSPARENT_HUGEPAGE
    run_cmd ./scripts/config --enable COMPACTION

    if (( $DMA_MIGRATION == 1 )) ; then
	scripts/config --enable CONFIG_DMA_MIGRATION
	scripts/config --module CONFIG_MIGRATION_OFFLOAD
    else
	scripts/config --disable CONFIG_DMA_MIGRATION
	scripts/config --disable CONFIG_MIGRATION_OFFLOAD
    fi

    if (( $TMPM == 1 )) ; then
	if (( $TEST == 1 && $PMIO == 1 )) ; then
	    scripts/config --enable CONFIG_TMPM_TEST_LIBRARY
	else
	    if (( !$PMIO && $TEST == 1)) ; then
		echo "CONFIG_TMPM_PAGE_MOVE_IO must be enabled to support CONFIG_TMPM_TEST_LIBRARY"
	    fi
	    scripts/config --disable CONFIG_TMPM_TEST_LIBRARY
	fi
	if (( $PMIO == 1 )) ; then
	    scripts/config --enable CONFIG_TMPM_PAGE_MOVE_IO
	else
	    scripts/config --disable CONFIG_TMPM_PAGE_MOVE_IO
	fi
	scripts/config --module CONFIG_AMD_TMPM
    fi

    grep -n CONFIG_KVM_AMD_SEV .config
    grep -in dma_migration .config
    grep -in config_tmpm_page_move_io .config
    grep TRANSPARENT .config
    grep COMPACTION .config
}

config_kernel()
{
    LOCAL_VER="$(git branch --show-current | cut -b -30)"

    if [[ ! -e ".config" ]] ; then
	run_cmd "cp /boot/config-$(uname -r) .config"
    fi

    run_cmd ./scripts/config --set-str CONFIG_LOCALVERSION "${LOCAL_VER//\//-}"
    grep CONFIG_LOCALVERSION .config | grep -v CONFIG_LOCALVERSION_AUTO

    run_cmd ./scripts/config --enable CRYPTO
    run_cmd ./scripts/config --enable CRYPTO_HW
    run_cmd ./scripts/config --enable CRYPTO_DEV_CCP_DD
    run_cmd ./scripts/config --enable CRYPTO_DEV_SP_PSP
    run_cmd ./scripts/config --enable  CONFIG_CRYPTO_DEV_CCP
    run_cmd ./scripts/config --enable CRYPTO_DEV_CCP_CRYPTO

    run_cmd ./scripts/config --enable CONFIG_X86_CPUID
    run_cmd ./scripts/config --enable EFI
    run_cmd ./scripts/config --enable EFI_STUB
    # some of the following are turin/tio settings
    run_cmd ./scripts/config --enable AMD_IOMMU
    run_cmd ./scripts/config --module CONFIG_IOMMUFD
    run_cmd ./scripts/config --enable CONFIG_IOMMUFD_VFIO_CONTAINER
    run_cmd ./scripts/config --module CONFIG_TSM_REPORTS
    run_cmd ./scripts/config --module CONFIG_SEV_GUEST
    run_cmd ./scripts/config --enable CONFIG_PCI
    run_cmd ./scripts/config --enable PCI_IOV
    run_cmd ./scripts/config --enable PCI_PRI
    run_cmd ./scripts/config --enable PCI_PASID
    run_cmd ./scripts/config --enable CONFIG_PCI_ATS
    run_cmd ./scripts/config --enable CONFIG_PCI_DOE
    run_cmd ./scripts/config --enable CONFIG_PCI_IDE
    run_cmd ./scripts/config --enable CONFIG_KVM
    run_cmd ./scripts/config --enable CONFIG_KVM_AMD

    run_cmd ./scripts/config --module RMPOPT
    run_cmd ./scripts/config --enable GUESTMEM

    run_cmd ./scripts/config --enable  EXPERT
    run_cmd ./scripts/config --enable  DEBUG_INFO
    run_cmd ./scripts/config --enable  DEBUG_INFO_REDUCED
    run_cmd ./scripts/config --enable  AMD_MEM_ENCRYPT
#    run_cmd ./scripts/config --disable AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT

    run_cmd ./scripts/config --disable CONFIG_DRM
    run_cmd ./scripts/config --enable KVM_AMD
    run_cmd ./scripts/config --enable  KVM_AMD_SEV
    run_cmd ./scripts/config --disable SYSTEM_TRUSTED_KEYS
    run_cmd ./scripts/config --disable SYSTEM_REVOCATION_KEYS
    run_cmd ./scripts/config --disable MODULE_SIG_KEY
    run_cmd ./scripts/config --module  SEV_GUEST
    run_cmd ./scripts/config --disable IOMMU_DEFAULT_PASSTHROUGH
    run_cmd ./scripts/config --disable PREEMPT_COUNT
    run_cmd ./scripts/config --disable PREEMPTION
    run_cmd ./scripts/config --disable PREEMPT_DYNAMIC
    run_cmd ./scripts/config --disable DEBUG_PREEMPT
    run_cmd ./scripts/config --enable  CGROUP_MISC
    run_cmd ./scripts/config --module  X86_CPUID
    run_cmd ./scripts/config --disable UBSAN
    run_cmd ./scripts/config --set-val RCU_EXP_CPU_STALL_TIMEOUT 1000
    run_cmd ./scripts/config --disable MLX4_EN
    run_cmd ./scripts/config --module MLX4_EN
    run_cmd ./scripts/config --enable MLX4_EN_DCB
    run_cmd ./scripts/config --module MLX4_CORE
    run_cmd ./scripts/config --enable MLX4_DEBUG
    run_cmd ./scripts/config --enable MLX4_CORE_GEN2
    run_cmd ./scripts/config --module MLX5_CORE
    run_cmd ./scripts/config --enable MLX5_FPGA
    run_cmd ./scripts/config --enable MLX5_CORE_EN
    run_cmd ./scripts/config --enable MLX5_EN_ARFS
    run_cmd ./scripts/config --enable MLX5_EN_RXNFC
    run_cmd ./scripts/config --enable MLX5_MPFS
    run_cmd ./scripts/config --enable MLX5_ESWITCH
    run_cmd ./scripts/config --enable MLX5_BRIDGE
    run_cmd ./scripts/config --enable MLX5_CLS_ACT
    run_cmd ./scripts/config --enable MLX5_TC_CT
    run_cmd ./scripts/config --enable MLX5_TC_SAMPLE
    run_cmd ./scripts/config --enable MLX5_CORE_EN_DCB
    run_cmd ./scripts/config --enable MLX5_CORE_IPOIB
    run_cmd ./scripts/config --enable MLX5_SW_STEERING
    run_cmd ./scripts/config --module MLXSW_CORE
    run_cmd ./scripts/config --enable MLXSW_CORE_HWMON
    run_cmd ./scripts/config --enable MLXSW_CORE_THERMAL
    run_cmd ./scripts/config --module MLXSW_PCI
    run_cmd ./scripts/config --module MLXSW_I2C
    run_cmd ./scripts/config --module MLXSW_SPECTRUM
    run_cmd ./scripts/config --enable MLXSW_SPECTRUM_DCB
    run_cmd ./scripts/config --module MLXSW_MINIMAL
    run_cmd ./scripts/config --module MLXFW
    run_cmd ./scripts/config --enable CONFIG_GUEST_MEMFD
    run_cmd ./scripts/config --enable CONFIG_HARDENED_USERCOPY

    run_cmd ./scripts/config --enable VIRT_DRIVERS
    run_cmd ./scripts/config --enable CONFIG_TSM
    run_cmd ./scripts/config --enable PCI_TSM
    run_cmd ./scripts/config --enable TSM_GUEST
    run_cmd ./scripts/config --enable TSM_HOST


    run_cmd ./scripts/config --enable CONFIG_BPF
    run_cmd ./scripts/config --enable CONFIG_BPF_SYSCALL
    run_cmd ./scripts/config --enable CONFIG_BPF_JIT
    run_cmd ./scripts/config --enable HAVE_EBPF_JIT
    run_cmd ./scripts/config --enable ARCH_WANT_DEFAULT_BPF_JIT
    run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO_BTF
    run_cmd ./scripts/config --enable CONFIG_DEBUG_INFO_BTF_MODULES

    run_cmd ./scripts/config --enable CONFIG_UPROBES
    run_cmd ./scripts/config --enable CONFIG_UPROBE_EVENTS
    run_cmd ./scripts/config --enable CONFIG_FTRACE
    run_cmd ./scripts/config --enable CONFIG_TRACING
    run_cmd ./scripts/config --enable CONFIG_FTRACE_SYSCALLS

    run_cmd ./scripts/config --disable MCR

    run_cmd ./scripts/config --module CONFIG_KSB

}

build_kernel()
{
	set -x
	kernel_type=$1
	shift
	mkdir -p linux
	pushd linux >/dev/null

	if [ ! -d guest ]; then
		run_cmd git clone ${KERNEL_GIT_URL} guest
		pushd guest >/dev/null
		run_cmd git remote add current ${KERNEL_GIT_URL}
		popd
	fi

	if [ ! -d host ]; then
		# use a copy of guest repo as the host repo
		run_cmd cp -r guest host
	fi

	for V in guest host; do
		# Check if only a "guest" or "host" or kernel build is requested
		if [ "$kernel_type" != "" ]; then
			if [ "$kernel_type" != "$V" ]; then
				continue
			fi
		fi

		if [ "${V}" = "guest" ]; then
			BRANCH="${KERNEL_GUEST_BRANCH}"
		else
			BRANCH="${KERNEL_HOST_BRANCH}"
		fi

		# If ${KERNEL_GIT_URL} is ever changed, 'current' remote will be out
		# of date, so always update the remote URL first. Also handle case
		# where AMDSEV scripts are updated while old kernel repos are still in
		# the directory without a 'current' remote
		pushd ${V} >/dev/null
		if git remote get-url current 2>/dev/null; then
			run_cmd git remote set-url current ${KERNEL_GIT_URL}
		else
			run_cmd git remote add current ${KERNEL_GIT_URL}
		fi
		popd >/dev/null

		# Nuke any previously built packages so they don't end up in new tarballs
		# when ./build.sh --package is specified
		rm -f linux-*-snp-${V}*

		VER="-snp-${V}"

		MAKE="make -C ${V} -j $(getconf _NPROCESSORS_ONLN) LOCALVERSION="

		run_cmd $MAKE distclean

		pushd ${V} >/dev/null
			run_cmd git fetch current
			run_cmd git checkout current/${BRANCH}
			COMMIT=$(git log --format="%h" -1 HEAD)

			run_cmd "cp /boot/config-$(uname -r) .config"
			run_cmd ./scripts/config --set-str LOCALVERSION "$VER-$COMMIT"

			run_cmd ./scripts/config --disable LOCALVERSION_AUTO

			#			config_kernel
			config_bpf

			grep -n CRYPTO_DEV_CCP_CRYPTO .config
			run_cmd ./scripts/config --disable TRANSPARENT_HUGEPAGE
			run_cmd ./scripts/config --disable COMPACTION

			run_cmd echo $COMMIT >../../source-commit.kernel.$V
		popd >/dev/null

#		yes "" | $MAKE olddefconfig

		# Build
		run_cmd $MAKE >/dev/null

		if [ "$ID" = "debian" ] || [ "$ID_LIKE" = "debian" ]; then
			run_cmd $MAKE bindeb-pkg
		else
			run_cmd $MAKE "RPMOPTS='--define \"_rpmdir .\"'" binrpm-pkg
			run_cmd mv ${V}/x86_64/*.rpm .
		fi
	done

	popd
}

build_install_ovmf()
{
	DEST="$1"

	GCC_VERSION=$(gcc -v 2>&1 | tail -1 | awk '{print $3}')
	GCC_MAJOR=$(echo $GCC_VERSION | awk -F . '{print $1}')
	GCC_MINOR=$(echo $GCC_VERSION | awk -F . '{print $2}')
	if [ "$GCC_MAJOR" == "4" ]; then
		GCCVERS="GCC${GCC_MAJOR}${GCC_MINOR}"
	else
		GCCVERS="GCC5"
	fi

	BUILD_CMD="nice build -q --cmd-len=64436 -DDEBUG_ON_SERIAL_PORT=TRUE -n $(getconf _NPROCESSORS_ONLN) ${GCCVERS:+-t $GCCVERS} -a X64 -p OvmfPkg/OvmfPkgX64.dsc"

	# initialize git repo, or update existing remote to currently configured one
	if [ -d edk2 ]; then
		pushd edk2 >/dev/null
		if git remote get-url current 2>/dev/null; then
			run_cmd git remote set-url current ${OVMF_GIT_URL}
		else
			run_cmd git remote add current ${OVMF_GIT_URL}
		fi
		popd >/dev/null
	else
		run_cmd git clone --single-branch -b ${OVMF_BRANCH} ${OVMF_GIT_URL} edk2
		pushd ovmf >/dev/null
		run_cmd git remote add current ${OVMF_GIT_URL}
		popd >/dev/null
	fi

	pushd edk2 >/dev/null
		run_cmd git fetch current
		run_cmd git checkout current/${OVMF_BRANCH}
		run_cmd git submodule update --init --recursive
		run_cmd make -C BaseTools
		. ./edksetup.sh --reconfig
		run_cmd $BUILD_CMD

		mkdir -p $DEST
		run_cmd cp -f Build/OvmfX64/DEBUG_$GCCVERS/FV/OVMF_CODE.fd $DEST
		run_cmd cp -f Build/OvmfX64/DEBUG_$GCCVERS/FV/OVMF_VARS.fd $DEST
		run_cmd cp -f Build/OvmfX64/DEBUG_$GCCVERS/FV/OVMF.fd $DEST

		COMMIT=$(git log --format="%h" -1 HEAD)
		run_cmd echo $COMMIT >../source-commit.ovmf
	popd >/dev/null
}

build_install_qemu()
{
	DEST="$1"

	if [ -n "$2" ]; then
	    # initialize git repo, or update existing remote to currently configured one
	    if [ -d qemu ]; then
		pushd qemu >/dev/null
		if git remote get-url current 2>/dev/null; then
		    run_cmd git remote set-url current ${QEMU_GIT_URL}
		else
		    run_cmd git remote add current ${QEMU_GIT_URL}
		fi
		popd >/dev/null
	    else
		run_cmd git clone --single-branch -b ${QEMU_BRANCH} ${QEMU_GIT_URL} qemu
		pushd qemu >/dev/null
		run_cmd git remote add current ${QEMU_GIT_URL}
		popd >/dev/null
	    fi
	    pushd qemu >/dev/null
	    run_cmd git fetch current
	    run_cmd git checkout current/${QEMU_BRANCH}
	    popd >/dev/null
	fi
	MAKE="make -k -j $(getconf _NPROCESSORS_ONLN) LOCALVERSION="
	pushd qemu >/dev/nullemacs
	run_cmd ./configure --target-list=x86_64-softmmu --prefix=$DEST \
		--enable-trace-backends="simple"

		run_cmd $MAKE
		run_cmd $MAKE install

		COMMIT=$(git log --format="%h" -1 HEAD)
		run_cmd echo $COMMIT >../source-commit.qemu
	popd >/dev/null
}
