#!/bin/bash
## Script for building R on AIX
## Author: Theussl
## Last change: 2009-06-16

## First define configure arguments for different compilers
configure_args=

## standard GNU compilers
configure_args_gnu="\
  CC=\"gcc -maix64 -pthread\" \
  CXX=\"g++ -maix64 -pthread\" \
  FC=\"gfortran -maix64 -pthread\" \
  F77=\"gfortran -maix64 -pthread\" \
  CFLAGS=\"-O2 -g -mcpu=power6\" \
  FFLAGS=\"-O2 -g -mcpu=power6\" \
  FCFLAGS=\"-O2 -g -mcpu=power6\"\
  MAKE=/opt/freeware/bin/make"

## IBM compilers and ESSL
configure_args_ibm="\
  --with-blas=\"-lessl -lblas\" \
  CC=xlc \
  CXX=xlc++ \
  FC=xlf \
  F77=xlf \
  CFLAGS=\"-qarch=auto -qcache=auto -qtune=auto -O3 -qstrict\" \
  FFLAGS=\"-qarch=auto -qcache=auto -qtune=auto -O3 -qstrict\" \
  FCFLAGS=\"-qarch=auto -qcache=auto -qtune=auto -O3 -qstrict\" \
  CXXFLAGS=\"-qarch=auto -qcache=auto -qtune=auto -O3 -qstrict\" \
  MAKE=/opt/freeware/bin/make"

while test -n "${1}"; do
    case "${1}" in
	--gnu)
	    configure_args=${configure_args_gnu}
	    COMPILER="gcc"
	    ;;
	--ibm)
	    configure_args=${configure_args_ibm}
	    COMPILER="xlc"
	    ;;
	*)
	    configure_args="${configure_args} ${1}"
	    ;;
    esac
    shift
done

if test -z "${COMPILER}"; then
    echo "No compilers specified"
    exit 1
fi

## Setup directories

BUILD_DIR=/home/theussl/src/Rbuild
SVN_SRC_DIR=/home/theussl/svn/R-2-9-branch
PATCH_AIX_R_ESSL=/home/theussl/AIX_scripts/aix_essl_R_m4.patch
PATCH_AIX_mgcv_gdi=/home/theussl/AIX_scripts/aix_mgcv_gdi_c.patch

DATE=`date +%y-%m-%d`
DIR_PREFIX=/usr/local/share/R
FLAVOR=R-patched

TARGET_DIR=${COMPILER}-build-${DATE}
INSTALL_DIR=${DIR_PREFIX}/${FLAVOR}/${TARGET_DIR}

## Everything set up -> build R

echo "$DATE: Start building R for AIX ..."
echo "#############################################################"

echo "Step 1: Initialization"
echo "#############################################################"

if [[ -d $BUILD_DIR ]] ; then
    echo "Remove old build directory ..."
    rm -rf $BUILD_DIR
fi

echo "Update SVN repository ..."
svn up $SVN_SRC_DIR

echo "Copy R sources to build directory ..."
cp -rp $SVN_SRC_DIR $BUILD_DIR

cd $BUILD_DIR

echo "Step 2: Apply R/AIX patches and sync recommended packages"
echo "#############################################################"

if [[ $COMPILERS = "xlc" ]] ; then
    echo "Patch R.m4 to allow ESSL on AIX ..."
    cat $PATCH_AIX_R_ESSL | patch ./m4/R.m4

    echo "Run aclocal ..."
    aclocal -I ./m4

    echo "Run autoconf ..."
    autoconf
fi

echo "Sync recommended packages ..."
./tools/rsync-recommended 

echo "Patch gdi.c in mgcv ..."
cd ./src/library/Recommended
tar xzf mgcv_*.tar.gz
cat $PATCH_AIX_mgcv_gdi | patch ./mgcv/src/gdi.c
rm mgcv_*.tar.gz
R CMD build mgcv
rm -rf ./mgcv
cd $BUILD_DIR


echo "Step 3: Configure R"
echo "#############################################################"

(eval ./configure --prefix=${INSTALL_DIR} ${configure_args})

echo "Step 4: Build R"
echo "#############################################################"

MAKE="make -j8" make

echo "Step 5: Install R"
echo "#############################################################"

echo "If you don't have sudo privileges go to $BUILD_DIR and type"
echo "'make install' as root to install R"

sudo make install

echo "Step 5: Finalization"
echo "#############################################################"

cd ${DIR_PREFIX}/${FLAVOR}
sudo rm -f current
sudo ln -s ${TARGET_DIR} current

echo "#############################################################"
echo "Done."
