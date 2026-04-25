# lib/options.nix
#
# Canonical option declarations shared by the NixOS, home-manager, and
# nix-darwin modules.  Each module imports this file and passes in the
# pkgs it received from its own module system.

{ lib, pkgs, self }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types;

  manifest = import ../pkgs/zephyr-sdk/toolchains.nix { inherit lib; };
in
{
  enable = mkEnableOption "Zephyr SDK";

  package = mkOption {
    type        = with types; nullOr package;
    default     = null;
    defaultText = lib.literalExpression "derived from programs.zephyr-sdk.gnu and .llvm options";
    description = ''
      Override the Zephyr SDK package.  When set to a non-null value the
      {option}`gnu` and {option}`llvm` sub-options are ignored and this
      package is used as-is.  Leave as `null` (the default) to let the
      module build the package from your toolchain selections.
    '';
  };

  gnu = {
    enable = mkOption {
      type        = types.bool;
      default     = true;
      description = ''
        Whether to include GNU cross-compilation toolchains in the SDK.
        When disabled no GNU toolchain tarballs are fetched or installed.
      '';
    };

    targets = mkOption {
      type    = with types; either (enum [ "all" ]) (listOf (enum manifest.allKnownGnuTargets));
      default = [ "arm-zephyr-eabi" ];
      example = lib.literalExpression ''[ "arm-zephyr-eabi" "riscv64-zephyr-elf" ]'';
      description = ''
        GNU toolchain targets to download and install.  Each entry must be
        one of the following strings (or use `"all"` to install every
        available target):

        ${lib.concatMapStrings (t: "  - `${t}`\n") manifest.allKnownGnuTargets}

        Only targets listed here will be fetched; the build is reproducible
        because each tarball is a fixed-output derivation with a known hash.
      '';
    };
  };

  llvm = {
    enable = mkOption {
      type    = types.bool;
      default = false;
      description = ''
        Whether to include the LLVM / Clang toolchain bundle in the SDK.
        The LLVM bundle is downloaded as a single additional tarball and
        extracted alongside the GNU toolchains.
      '';
    };
  };

  enableShellIntegration = mkOption {
    type    = types.bool;
    default = true;
    description = ''
      When enabled the module exports the environment variables that CMake
      and west need to locate the SDK:

        {env}`ZEPHYR_SDK_INSTALL_DIR`   — points at the container `$out`
                                           directory for multi-SDK discovery
        {env}`ZEPHYR_TOOLCHAIN_VARIANT` — always set to `"zephyr"` to
                                           select the Zephyr bundled compilers

      These variables are fixed by the package and are not user-configurable.
    '';
  };

  # ------------------------------------------------------------------ #
  #  Extra environment variables                                        #
  # ------------------------------------------------------------------ #

  extraEnv = mkOption {
    type    = types.attrsOf types.str;
    default = { };
    example = lib.literalExpression ''
      {
        ZEPHYR_BASE = "''${config.home.homeDirectory}/zephyrproject/zephyr";
        # Pin to the exact versioned SDK directory rather than the container:
        # ZEPHYR_SDK_INSTALL_DIR = "''${config.programs.zephyr-sdk.package}/zephyr-sdk-0.16.8";
      }
    '';
    description = ''
      Additional environment variables to inject alongside the SDK variables.
      Useful for setting `ZEPHYR_BASE` or overriding `ZEPHYR_SDK_INSTALL_DIR`
      to pin a specific version rather than relying on auto-discovery.
    '';
  };
}
