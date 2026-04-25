# modules/darwin.nix
#
# nix-darwin module for the Zephyr SDK.
#
# Usage in a nix-darwin flake:
#
#   {
#     inputs = {
#       nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
#       darwin.url     = "github:LnL7/nix-darwin";
#       zephyr-nix.url = "github:yourorg/zephyr-nix";
#     };
#
#     outputs = { darwin, zephyr-nix, ... }: {
#       darwinConfigurations.myMac = darwin.lib.darwinSystem {
#         system  = "aarch64-darwin";
#         modules = [
#           zephyr-nix.darwinModules.default
#           {
#             programs.zephyr-sdk = {
#               enable = true;
#               toolchain.gnu.enable     = true;
#               toolchain.gnu.toolchains = [ "arm-zephyr-eabi" ];
#               # toolchain.llvm.enable = true;  # macOS users may prefer Clang
#             };
#           }
#           ./darwin-configuration.nix
#         ];
#       };
#     };
#   }

{ self }:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;

  optionDecls = import ../lib/options.nix { inherit lib pkgs self; };
  cfg         = config.programs.zephyr-sdk;

  # Resolve the SDK package from the user's gnu/llvm options, unless they
  # have supplied a fully custom package via programs.zephyr-sdk.package.
  resolvedPackage =
    if cfg.package != null
    then cfg.package
    else self.packages.${pkgs.stdenv.hostPlatform.system}.zephyr-sdk.override {
      gnuToolchains = if cfg.toolchain.gnu.enable then cfg.toolchain.gnu.toolchains else [];
      enableLlvm    = cfg.toolchain.llvm.enable;
    };

  impl = import ../lib/implementation.nix {
    inherit lib cfg pkgs;
    package = resolvedPackage;
  };
in
{
  # ------------------------------------------------------------------ #
  #  Option declarations                                                #
  # ------------------------------------------------------------------ #
  options.programs.zephyr-sdk = with lib; {
    inherit (optionDecls)
      enable
      package
      toolchain
      enableShellIntegration
      extraEnv;
  };

  # ------------------------------------------------------------------ #
  #  Configuration                                                      #
  # ------------------------------------------------------------------ #
  config = mkIf cfg.enable {

    # Install the SDK into the system profile.
    environment.systemPackages = impl.packages;

    # nix-darwin exposes system-wide environment variables via this option.
    environment.variables = impl.sessionVariables;
  };
}
