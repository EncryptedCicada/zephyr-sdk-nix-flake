# lib/options.nix
#
# Canonical option declarations shared by the NixOS, home-manager, and
# nix-darwin modules.  Each module imports this file and passes in the
# pkgs it received from its own module system so that the default package
# is evaluated in the right context.

{ lib, pkgs, self }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    types;
in
{
  # ------------------------------------------------------------------ #
  #  Top-level option group                                             #
  # ------------------------------------------------------------------ #

  enable = mkEnableOption "Zephyr SDK";

  package = mkOption {
    type        = types.package;
    default     = self.packages.${pkgs.stdenv.hostPlatform.system}.zephyr-sdk;
    defaultText = lib.literalExpression "zephyr-nix.packages.\${system}.zephyr-sdk";
    description = ''
      The Zephyr SDK package to use.  Override this to pin a different
      version or to supply your own derivation with custom toolchain
      variants built in.
    '';
  };

  enableShellIntegration = mkOption {
    type        = types.bool;
    default     = true;
    description = ''
      When enabled the module will export the environment variables that
      CMake and west need to locate the SDK:

        ZEPHYR_SDK_INSTALL_DIR
        ZEPHYR_TOOLCHAIN_VARIANT
    '';
  };

  toolchainVariant = mkOption {
    type    = types.str;
    default = "zephyr";
    example = "gnuarmemb";
    description = ''
      Value written to {env}`ZEPHYR_TOOLCHAIN_VARIANT`.  The default
      ``"zephyr"`` selects the bundled Zephyr toolchain.  Set to
      ``"gnuarmemb"`` or another variant when you supply your own
      cross-compiler outside the SDK.
    '';
  };

  extraEnv = mkOption {
    type    = types.attrsOf types.str;
    default = { };
    example = lib.literalExpression ''
      { ZEPHYR_BASE = "''${config.home.homeDirectory}/zephyrproject/zephyr"; }
    '';
    description = ''
      Additional environment variables to inject alongside the SDK
      variables.  Useful for pointing `ZEPHYR_BASE` at a workspace
      managed outside of Nix.
    '';
  };
}
