# modules/home-manager.nix
#
# home-manager module for the Zephyr SDK.
#
# Usage — standalone home-manager flake:
#
#   {
#     inputs = {
#       nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
#       home-manager.url = "github:nix-community/home-manager";
#       zephyr-nix.url   = "github:yourorg/zephyr-nix";
#     };
#
#     outputs = { home-manager, zephyr-nix, nixpkgs, ... }: {
#       homeConfigurations."alice" = home-manager.lib.homeManagerConfiguration {
#         pkgs    = nixpkgs.legacyPackages.x86_64-linux;
#         modules = [
#           zephyr-nix.homeManagerModules.default
#           {
#             programs.zephyr-sdk = {
#               enable = true;
#               toolchain.gnu.enable     = true;
#               toolchain.gnu.toolchains = [ "arm-zephyr-eabi" ];
#             };
#           }
#         ];
#       };
#     };
#   }
#
# Usage — embedded inside a NixOS or nix-darwin config that already uses
# the home-manager NixOS/Darwin module:
#
#   home-manager.users.alice = {
#     imports = [ zephyr-nix.homeManagerModules.default ];
#     programs.zephyr-sdk = {
#       enable = true;
#       toolchain.gnu.enable     = true;
#       toolchain.gnu.toolchains = [ "arm-zephyr-eabi" "riscv64-zephyr-elf" ];
#     };
#   };

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

    # Add the SDK to the user's profile.
    home.packages = impl.packages;

    # Per-user session variables written to ~/.profile, ~/.bash_profile, etc.
    home.sessionVariables = impl.sessionVariables;
  };
}
