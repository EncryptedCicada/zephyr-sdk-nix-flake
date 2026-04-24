# pkgs/zephyr-sdk/default.nix
#
# Zephyr SDK package for NixOS, nix-darwin, and generic Nix.
#
# The SDK ships as a self-contained tarball with pre-built cross-compilers and
# host tools.  On Linux those binaries are dynamically linked against glibc
# paths that do not exist on NixOS, so every ELF binary must be patched with
# patchelf before it is usable.  On macOS the binaries are already compatible
# with a standard Darwin userland, but cmake / Python helpers still need their
# shebangs fixed.
#
# Patching is handled inside the installPhase below.  As new toolchain
# variants are added (see `toolchains` option) the same logic applies to each
# one.

{ lib
, stdenv
, stdenvNoCC
, fetchurl
, autoPatchelfHook   # Linux only — rewrites ELF RPATH / interpreter
, patchelf           # called explicitly for finer-grained control
, python3
, cmake
, ninja
, dtc
, gperf
, openssl
, wget
, which
, zlib
, libusb1
, udev              # Linux only
, libudev-zero      # portable udev stub (Linux fallback)
  # SDK version to fetch — override via `override` or a flake argument
, sdkVersion ? "1.0.1"
}:

let
  # ------------------------------------------------------------------ #
  #  Per-system source information                                       #
  # ------------------------------------------------------------------ #
  #
  # SHA-256 hashes must be filled in after running:
  #
  #   nix-prefetch-url <url>
  #
  # or by letting Nix tell you the correct hash on the first failed build.
  #
  sources = {
    "x86_64-linux" = {
      url    = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdkVersion}/zephyr-sdk-${sdkVersion}_linux-x86_64_minimal.tar.xz";
      sha256 = "sha256-ypvA/2b6/KHaydWSo22VPPFtCWqdCbHANX8CHPn2p+s=";
    };
    "aarch64-linux" = {
      url    = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdkVersion}/zephyr-sdk-${sdkVersion}_linux-aarch64_minimal.tar.xz";
      sha256 = "sha256-15xb/GjmeUiGWb6iiaQCblKmTwMziHXIychQ//E87jA=";
    };
    "aarch64-darwin" = {
      url    = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdkVersion}/zephyr-sdk-${sdkVersion}_macos-aarch64_minimal.tar.xz";
      sha256 = "sha256-hnBjkB85UophdagOvCA2e9bLRAWT5+JlDtowOS8fa2U=";
    };
  };

  system = stdenv.hostPlatform.system;
  src-info = sources.${system} or (throw "zephyr-sdk: unsupported system ${system}");

  isLinux  = stdenv.isLinux;
  isDarwin = stdenv.isDarwin;

in
stdenvNoCC.mkDerivation rec {
  pname   = "zephyr-sdk";
  version = sdkVersion;

  src = fetchurl {
    inherit (src-info) url sha256;
  };

  # Don't let Nix's generic unpackers strip or move things unexpectedly.
  dontStrip     = true;
  dontPatchELF  = true; # we do this ourselves
  dontAutoPatchelf = true;

  # ------------------------------------------------------------------ #
  #  Build inputs                                                        #
  # ------------------------------------------------------------------ #
  nativeBuildInputs = lib.optionals isLinux [
    autoPatchelfHook
    patchelf
  ];

  buildInputs = [
    python3
    cmake
    ninja
    dtc
    gperf
    openssl
    zlib
  ] ++ lib.optionals isLinux [
    libusb1
    udev
  ];

  # ------------------------------------------------------------------ #
  #  Unpack                                                              #
  # ------------------------------------------------------------------ #
  # The upstream tarball contains a top-level directory named
  # "zephyr-sdk-<version>".  We unpack into a temporary location and
  # then rename it to a predictable path.
  unpackPhase = ''
    runHook preUnpack
    tar -xf $src
    mv zephyr-sdk-${version} sdk-src
    runHook postUnpack
  '';

  # ------------------------------------------------------------------ #
  #  Install                                                             #
  # ------------------------------------------------------------------ #
  installPhase = ''
    runHook preInstall

    # Copy the entire SDK tree into $out
    mkdir -p $out
    cp -r sdk-src/. $out/

    # ---------------------------------------------------------------- #
    # Linux: patch all ELF binaries so they find glibc in the Nix store
    # ---------------------------------------------------------------- #
    if [ "${lib.boolToString isLinux}" = "true" ]; then
      echo "Patching ELF binaries..."

      # Walk every regular file and patch those that are ELF executables or
      # shared libraries.  autoPatchelfHook is *also* active but we call
      # patchelf explicitly here so we have a clear record of what was done.
      find $out -type f | while read f; do
        # Skip symlinks and non-ELF files quickly
        magic=$(head -c 4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n' || true)
        if [ "$magic" = "7f454c46" ]; then
          patchelf \
            --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
            --set-rpath "${lib.makeLibraryPath buildInputs}" \
            "$f" 2>/dev/null || true
        fi
      done
    fi

    # ---------------------------------------------------------------- #
    # All platforms: fix Python shebangs                                #
    # ---------------------------------------------------------------- #
    echo "Patching shebangs..."
    find $out -type f -name "*.py" | xargs -r sed -i \
      "s|#!/usr/bin/env python3|#!${python3}/bin/python3|g"
    find $out -type f -name "*.py" | xargs -r sed -i \
      "s|#!/usr/bin/python3|#!${python3}/bin/python3|g"

    # ---------------------------------------------------------------- #
    # Write a zephyrrc that downstream tooling / shell init can source  #
    # ---------------------------------------------------------------- #
    mkdir -p $out/share/zephyr-sdk
    cat > $out/share/zephyr-sdk/zephyrrc <<EOF
    # Auto-generated by the zephyr-sdk Nix package — do not edit by hand.
    export ZEPHYR_SDK_INSTALL_DIR="$out"
    export ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
    EOF

    runHook postInstall
  '';

  # ------------------------------------------------------------------ #
  #  Post-fixup: run autoPatchelfHook's finalisation on Linux           #
  # ------------------------------------------------------------------ #
  # autoPatchelfHook scans $out *after* installPhase in its own
  # fixupPhase hook, so our explicit patchelf calls above and the hook
  # together handle the full fixup.

  # ------------------------------------------------------------------ #
  #  Meta                                                                #
  # ------------------------------------------------------------------ #
  meta = with lib; {
    description  = "Zephyr RTOS toolchain SDK";
    longDescription = ''
      The Zephyr SDK provides cross-compilation toolchains, host tools, and
      debugging utilities for building Zephyr RTOS firmware.  It supports a
      wide range of target architectures including ARM, RISC-V, x86, Xtensa,
      and more.
    '';
    homepage    = "https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html";
    license     = licenses.asl20;
    platforms   = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    maintainers = [ ];
  };
}
