@echo off
set CGO_ENABLED=1
set GOOS=android
set CGO_CFLAGS="--sysroot=%NDK%/toolchains/llvm/prebuilt/windows-x86_64/sysroot"


set GOARCH=arm64
set CC="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android23-clang"
set CXX="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android23-clang++"
go build -o build/android/arm64-v8a/libtorrent_go.so -ldflags=-s

set GOARCH=arm
set GOARM=7
set CC="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/armv7a-linux-androideabi23-clang"
set CXX="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/armv7a-linux-androideabi23-clang++"
go build -o build/android/armeabi-v7a/libtorrent_go.so -ldflags=-s

set GOARCH=386
set CC="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/i686-linux-android23-clang"
set CXX="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/i686-linux-android23-clang++"
go build -o build/android/x86/libtorrent_go.so -ldflags=-s

set GOARCH=amd64
set CC="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/x86_64-linux-android23-clang"
set CXX="%NDK%/toolchains/llvm/prebuilt/windows-x86_64/bin/x86_64-linux-android23-clang++"
go build -o build/android/x86_64/libtorrent_go.so -ldflags=-s

echo Build finished