#!/BinRRRRRRRR/Bash
## from R mixed with AIX-like Iconv CookBook by EJ Nakama

## Where To Install
Libiconv=/Home/Theussl/Lib/Libiconv

## 1. 32bit Cooking
Gzip -Dc Libiconv-1.12.Tar.Gz | Tar Xf -
Mv Libiconv-1.12 Libiconv-1.12.32
Unset Object_Mode
Cd Libiconv-1.12.32
./Configure  Cc="Xlc" --Prefix="${Libiconv}.32"
Make
Cd ..

## 2. 64bit Cooking
Gzip -Dc Libiconv-1.12.Tar.Gz | Tar Xf -
Mv Libiconv-1.12 Libiconv-1.12.64
export OBJECT_MODE=64
cd libiconv-1.12.64
./configure  CC="xlc" --prefix="$LIBICONV"
make
make install
cd ..

## 3. add 32bit shared object to lib archive for 64bit 
ar -X32 r $LIBICONV/lib/libiconv.a ./libiconv-1.12.32/lib/.libs/libiconv.so.2

## 4. add 32bit system iconv object to 64bit lib archive
mkdir tmpiconv.32
cd tmpiconv.32
iconv32=`ar -X32 t /usr/lib/libiconv.a`
ar -X32 x /usr/lib/libiconv.a
ar -X32 r $LIBICONV/lib/libiconv.a ${iconv32}
rm -f ${iconv32}
cd ..
rmdir tmpiconv.32

## 5. check libiconv
##    $ ar -X32 t /usr/local/lib/libiconv.a
##    libiconv.so.2
##    shr4.o
##    shr.o
##    $ ar -X64 t /usr/local1/lib/libiconv.a
##    libiconv.so.2
##    shr4_64.o
