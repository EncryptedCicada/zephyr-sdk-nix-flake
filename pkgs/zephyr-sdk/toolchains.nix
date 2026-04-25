# pkgs/zephyr-sdk/toolchains.nix
#
# Version manifest and hash-file utilities for the Zephyr SDK.
#
# Design
# ------
# Rather than maintaining a static table of hundreds of SHA-256 hashes, each
# SDK release publishes a sha256.sum file containing the hash of every asset.
# We fetch that file as a single fixed-output derivation (whose hash is the
# only value we need to hardcode per release) and parse it at Nix evaluation
# time via builtins.readFile to obtain the hash for every other asset.
#
# Similarly, rather than maintaining a hand-written list of GNU toolchain
# targets, we store the verbatim content of sdk_gnu_toolchains (a file that
# ships in the SDK bundle root alongside setup.sh) and parse it here.  To
# update for a new release, extract the bundle and copy the file content into
# the new version entry.
#
# This file requires Import From Derivation (IFD) for the sha256.sum lookup.
# IFD is enabled by default.  If your configuration sets
# allow-import-from-derivation = false, add:
#
#   extra-config = allow-import-from-derivation = true
#
# to /etc/nix/nix.conf, or pass --allow-import-from-derivation to nix commands.
#
# Adding a new SDK version
# ------------------------
# 1. Download and verify the sha256.sum for the new release:
#
#      nix-prefetch-url \
#        https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v<ver>/sha256.sum
#
# 2. Extract the minimal bundle and read the sdk_gnu_toolchains file from the root.
#
# 3. Add a new entry under `versions` with both values.

{ lib }:

rec {
  hostStrings = {
    "x86_64-linux"   = "linux-x86_64";
    "aarch64-linux"  = "linux-aarch64";
    "aarch64-darwin" = "macos-aarch64";
  };

  parseGnuToolchainsFile = content:
    lib.filter (l: l != "") (lib.splitString "\n" (lib.trim content));

  # ------------------------------------------------------------------ #
  #  Per-version metadata                                                #
  # ------------------------------------------------------------------ #

  versions = {
    "1.0.1" = {
      # Hash of the sha256.sum file itself, obtained via nix-prefetch-url.
      sha256sumHash = "sha256:ea547002a221dc5eceec908feab1c04977bb95589e22b6bfc6d6661c0cf7456a";

      # Verbatim content of sdk_gnu_toolchains from the bundle root.
      # Obtained by extracting zephyr-sdk-1.0.1_<host>_minimal.tar.xz
      # and reading zephyr-sdk-1.0.1/sdk_gnu_toolchains.
      gnuToolchainsFile = ''
        aarch64-zephyr-elf
        arc64-zephyr-elf
        arc-zephyr-elf
        arm-zephyr-eabi
        microblazeel-zephyr-elf
        mips-zephyr-elf
        or1k-zephyr-elf
        riscv64-zephyr-elf
        rx-zephyr-elf
        sparc-zephyr-elf
        x86_64-zephyr-elf
        xtensa-amd_acp_6_0_adsp_zephyr-elf
        xtensa-amd_acp_7_0_adsp_zephyr-elf
        xtensa-amd_acp_7_3_adsp_zephyr-elf
        xtensa-dc233c_zephyr-elf
        xtensa-espressif_esp32_zephyr-elf
        xtensa-espressif_esp32s2_zephyr-elf
        xtensa-espressif_esp32s3_zephyr-elf
        xtensa-intel_ace15_mtpm_zephyr-elf
        xtensa-intel_ace30_ptl_zephyr-elf
        xtensa-intel_ace40_zephyr-elf
        xtensa-intel_tgl_adsp_zephyr-elf
        xtensa-mtk_mt8195_adsp_zephyr-elf
        xtensa-mtk_mt818x_adsp_zephyr-elf
        xtensa-mtk_mt8196_adsp_zephyr-elf
        xtensa-mtk_mt8365_adsp_zephyr-elf
        xtensa-nxp_imx_adsp_zephyr-elf
        xtensa-nxp_imx8m_adsp_zephyr-elf
        xtensa-nxp_imx8ulp_adsp_zephyr-elf
        xtensa-nxp_rt500_adsp_zephyr-elf
        xtensa-nxp_rt600_adsp_zephyr-elf
        xtensa-nxp_rt700_hifi1_zephyr-elf
        xtensa-nxp_rt700_hifi4_zephyr-elf
        xtensa-sample_controller_zephyr-elf
        xtensa-sample_controller32_zephyr-elf
      '';
    };
  };

  gnuTargetsForVersion = version:
    parseGnuToolchainsFile versions.${version}.gnuToolchainsFile;

  allKnownGnuTargets =
    lib.unique (lib.concatMap
      (v: parseGnuToolchainsFile v.gnuToolchainsFile)
      (lib.attrValues versions));

  # ------------------------------------------------------------------ #
  #  sha256.sum parser                                                   #
  # ------------------------------------------------------------------ #
  # Parses the text content of a sha256.sum file into an attrset mapping
  # filename → sha256-hex-string.
  #
  # sha256.sum line format:  <64-hex-chars>  <filename>
  # (two spaces between hash and filename, as produced by sha256sum(1))

  parseHashFile = content:
    let
      lines     = lib.filter (l: l != "") (lib.splitString "\n" content);
      parseLine = line:
        let m = builtins.match "([0-9a-f]{64})  (.+)" line;
        in if m == null then null
           else lib.nameValuePair (lib.elemAt m 1) (lib.elemAt m 0);
    in
    lib.listToAttrs (lib.filter (x: x != null) (map parseLine lines));

  # ------------------------------------------------------------------ #
  #  URL constructors                                                    #
  # ------------------------------------------------------------------ #

  releaseBaseUrl = version:
    "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}";

  sha256sumUrl = version: "${releaseBaseUrl version}/sha256.sum";
  bundleUrl    = { version, hostStr }: "${releaseBaseUrl version}/zephyr-sdk-${version}_${hostStr}_minimal.tar.xz";
  gnuUrl       = { version, hostStr, target }: "${releaseBaseUrl version}/toolchain_gnu_${hostStr}_${target}.tar.xz";
  llvmUrl      = { version, hostStr }: "${releaseBaseUrl version}/toolchain_llvm_${hostStr}.tar.xz";
}
