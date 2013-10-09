TARGET_LIST=""
BUILD_DIR="."
CHECK=0
MAKE=0
CONF=0
CLEAN=0
INSTALL=0

usage() {
    echo "$0 --x86 or ppc  to configure for the x86 or ppc64 target only"
    echo "$0 --long to configure for x86, s390, ppc64 and arm targets"
    echo "$0 --med to configure for x86 and ppc64 targets"
    echo "$0 --all to configure for all targets (default)"
    echo "add the --dir=<dir> parameter to specify a working directory"
}

if [ $# -lt 1 ] ; then
    usage
fi

until [ -z "$1" ]; do    
    case "${1:0:2}" in
        "--")
        case "${1:2:3}" in 
            "x86") CONF=1; TARGET_LIST="x86_64-softmmu";;
            "lon") CONF=1; 
		   TARGET_LIST="arm-softmmu,ppc64-softmmu,s390x-softmmu,x86_64-softmmu";;
	    "med") CONF=1; 
		   TARGET_LIST="ppc64-softmmu,x86_64-softmmu";;
	    "ppc") CONF=1; 
		   TARGET_LIST="ppc64-softmmu";;
            "all") CONF=1;;
	    "dir") BUILD_DIR="${1##--dir=}";;
            "hel") usage ;;
	    "che") CHECK=1;;
	    "cle") CLEAN=1;;
	    "ins") INSTALL=1;;
	    "mak") MAKE=1;;
        esac ;;
        *)usage;;
    esac
        shift;
done

echo "$CONF, $CHECK, $MAKE, $CLEAN"

if [ $CONF -ne 0 ] ; then
    pushd $BUILD_DIR

# make sure we have the submodules

    if [ ! -f dtc/.git ] ; then 
	git submodule update --init dtc
    fi 

    ./configure --target-list=$TARGET_LIST

# if we don't have the checkpatch hook installed, do it now
    if [ ! -f .git/hooks/pre-commit ] ; then
	(
	cat  <<'EOF'
#!/bin/bash
exec git diff --cached | scripts/checkpatch.pl --no-signoff -q -
EOF
        ) >> .git/hooks/pre-commit
	chmod 755 .git/hooks/pre-commit
    fi 
    popd

# if we don't have the commit-msg hook, add it now
    if [ ! -f .git/hooks/prepare-commit-msg ] ; then
	(
	cat <<'EOF'
SOB=$(git var GIT_AUTHOR_IDENT | sed -n 's/^\(.*>\).*$/Signed-off-by: \1/p')
grep -qs "^$SOB" "$1" || echo "$SOB" >> "$1"
EOF
	) >> .git/hooks/prepare-commit-msg
       chmod 755 .git/hooks/prepare-commit-msg
    fi
fi

if [ $CLEAN -ne 0 ] ; then
    pushd "$BUILD_DIR"
    make clean
    popd
fi

if [ $MAKE -ne 0 ] ; then
    pushd "$BUILD_DIR"
    make 
    popd
fi

if [ $INSTALL -ne 0 ] ; then
    pushd "$BUILD_DIR"
    sudo make install 
    popd
fi

if [ $CHECK -ne 0 ] ; then
    pushd "$BUILD_DIR"
    make check
    popd
fi
