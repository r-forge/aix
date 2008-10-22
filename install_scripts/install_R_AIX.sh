
echo "Start building R for AIX ..."

BUILD_DIR=/home/theussl/src/Rbuild
SVN_SRC_DIR=/home/theussl/svn/R-2-8-branch
AIX_PATCH=/home/theussl/AIX_scripts/aix_essl_R_m4.patch
R_CONFIGURE=/home/theussl/AIX_scripts/Rconf_xlc_essl

if [[ -d $BUILD_DIR ]] ; then
    echo "Remove old build directory ..."
    rm -rf $BUILD_DIR
fi

echo "Update SVN repository ..."
svn up $SVN_SRC_DIR

echo "Copy R sources to build directory ..."
cp -rp $SVN_SRC_DIR $BUILD_DIR

cd $BUILD_DIR

echo "Patch R.m4 to allow ESSL on AIX ..."
cat $AIX_PATCH | patch ./m4/R.m4

echo "Run aclocal ..."
aclocal -I ./m4

echo "Run autoconf ..."
autoconf

echo "Sync recommended packages ..."
./tools/rsync-recommended 

echo "Configure R ..."
$R_CONFIGURE 

echo "Done."


