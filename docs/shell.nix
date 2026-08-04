# Used to build Samsung Tab S9 (SM-X710 - gts9wifi) Kernel on NixOS
# 
# History:
#   https://gist.github.com/Arian04/bea169c987d46a7f51c63a68bc117472
#   https://gist.github.com/Nadrieril/d006c0d9784ba7eff0b092796d78eb2a
#   https://nixos.wiki/wiki/Android#Building_Android_on_NixOS

{pkgs ? import <nixpkgs> {}}: let
  hostLlvmSysroot = pkgs.runCommand "host-llvm-sysroot" {} ''
    mkdir -p $out/usr/lib $out/usr/lib/x86_64-linux-gnu $out/lib/x86_64-linux-gnu $out/lib64
    for d in usr/lib usr/lib/x86_64-linux-gnu lib/x86_64-linux-gnu lib64; do
      ln -sf ${pkgs.glibc}/lib/crt1.o $out/$d/crt1.o
      ln -sf ${pkgs.glibc}/lib/crti.o $out/$d/crti.o
      ln -sf ${pkgs.glibc}/lib/crtn.o $out/$d/crtn.o
      ln -sf ${pkgs.gcc.cc}/lib/gcc/*/*/crtbegin.o $out/$d/crtbegin.o
      ln -sf ${pkgs.gcc.cc}/lib/gcc/*/*/crtend.o $out/$d/crtend.o
      ln -sf ${pkgs.gcc.cc}/lib/gcc/*/*/libgcc.a $out/$d/libgcc.a
      ln -sf ${pkgs.libgcc}/lib/libgcc_s.so $out/$d/libgcc_s.so
      ln -sf ${pkgs.libgcc}/lib/libgcc_s.so.1 $out/$d/libgcc_s.so.1
      ln -sf ${pkgs.glibc}/lib/libc.so.6 $out/$d/libc.so.6
      ln -sf ${pkgs.glibc}/lib/libc_nonshared.a $out/$d/libc_nonshared.a
      ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/$d/ld-linux-x86-64.so.2
    done
    ln -s ${pkgs.glibc.dev}/include $out/usr/include
    printf 'OUTPUT_FORMAT(elf64-x86-64) GROUP ( libc.so.6 libc_nonshared.a AS_NEEDED ( ld-linux-x86-64.so.2 ) )' > $out/usr/lib/libc.so
  '';
  fhs = pkgs.buildFHSEnv {
    name = "android-env";
    targetPkgs = pkgs:
      with pkgs; [
        glibc.dev
        cacert
        android-tools
        libxcrypt-legacy # libcrypt.so.1
        freetype # libfreetype.so.6
        fontconfig # java NPE: "sun.awt.FontConfiguration.head" is null
        yaml-cpp # necessary for some kernels according to a comment on the gist
        # Some of the packages here are probably unecessary but I don't wanna figure out which
        bc
        binutils
        bison
        ccache
        curl
        flex
        gcc
        pahole # provides pahole, needed for CONFIG_DEBUG_INFO_BTF (vmlinux BTF)
        git
        git-repo
        git-lfs
        gnumake
        gnupg
        gperf
        imagemagick
        jdk11
        elfutils
        libxml2
        libxslt
        lz4
        zstd.out # libzstd.so.1 (libelf dep) - default output is bin, so force .out
        xz # liblzma.so.5 (libelf dep)
        bzip2 # libbz2.so.1 (libelf dep)
        libabigail # provides abidw
        xxd
        lzop
        m4
        nettools
        openssl.dev
        openssl
        perl
        pngcrush
        procps
        python3
        rsync
        schedtool
        SDL
        squashfsTools
        unzip
        util-linux
        xml2
        zip
        lld
        bash
      ];
    multiPkgs = pkgs:
      with pkgs; [
        zlib
        ncurses5
        libcxx
        readline
        glibc.dev # sys/types.h etc.
        elfutils.dev # libelf.h / gelf.h for resolve_btfids
        zlib.dev # zlib.h (parallel build may link libbpf against it)
        libgcc
        iconv
      ];
    runScript = "${pkgs.bash}/bin/bash";
    profile = ''
      export ALLOW_NINJA_ENV=true

      # add prebuilts clang
      export PATH="$PWD/kernel_platform/prebuilts/clang/host/linux-x86/clang-r450784e/bin:$PATH"

      export HOST_LLVM_SYSROOT=${hostLlvmSysroot}
      export HOST_LLVM_SPLIT="-L /usr/lib -L /usr/lib/x86_64-linux-gnu -L /lib -L /lib64"
      export HOST_LINK_SYSRC_FLAG="$HOST_LLVM_SYSROOT --sysroot-flags"

      # portions of the toolchain are grossly incompatible with NixOS currently and im too lazy to fix, so just disable
      export HERMETIC_TOOLCHAIN=0

      export CCACHE_EXEC=/usr/bin/ccache
      export ANDROID_JAVA_HOME=${pkgs.jdk11.home}
      export TMPDIR=/tmp
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.ncurses5}/lib
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

      # disable strict mode for KMI symbol list generation
      export KMI_SYMBOL_LIST_STRICT_MODE=0
      # export MODULES_ORDER=

      export SYSTEM_DLKM_RE_SIGN=0
      export BUILD_SYSTEM_DLKM=1

      export HOST_LLVM_LINK_RPATH="-Wl,-rpath-link,/usr/lib64 -Wl,-rpath-link,$HOST_LLVM_SYSROOT/lib"
      export HOSTCFLAGS="--sysroot=$HOST_LLVM_SYSROOT -idirafter /usr/include -Wno-unused-command-line-argument"
      export HOSTLDFLAGS="--sysroot=$HOST_LLVM_SYSROOT $HOST_LLVM_SPLIT $HOST_LLVM_LINK_RPATH -Wno-unused-command-line-argument"

      export NDK_SYSROOT="$PWD/kernel_platform/prebuilts/ndk-r23/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
      export USERCFLAGS="--target=aarch64-linux-android30 --sysroot=$NDK_SYSROOT -Wno-unused-command-line-argument"
      export USERLDFLAGS="--target=aarch64-linux-android30 --sysroot=$NDK_SYSROOT -fuse-ld=lld -Wno-unused-command-line-argument"
      
      # kernel_platform/msm-kernel/build.config.gki.aarch64 kernel_platform/common/build.config.gki.aarch64
      # `BUILD_GKI_CERTIFICATION_TOOLS=0` # might be needed?

      # uncomment to enable verbose logging
      # export KBUILD_VERBOSE=1
    '';
  };
in
  pkgs.stdenv.mkDerivation {
    name = "android-env-shell";
    nativeBuildInputs = [fhs];
    shellHook = "exec android-env";
  }
