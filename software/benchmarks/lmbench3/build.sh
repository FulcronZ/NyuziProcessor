OS=nyuzi-linux-gnu
COMPILER_DIR=/usr/local/llvm-nyuzi/bin
CC=$COMPILER_DIR/clang
INC_DIR="-I$PWD/../../libs/libc/include -I$PWD/../../libs/libos -I$PWD/../../libs/libos/$OS -I/usr/include -I/usr/include/x86_64-linux-gnu"
export CFLAGS="$PWD/../../libs/libc/crt0.o $PWD/../../libs/libc/libc.a $INC_DIR"
export CPPFLAGS=$CFLAGS
AR=$COMPILER_DIR/llvm-ar

make CC=$CC OS=$OS AR=$AR
