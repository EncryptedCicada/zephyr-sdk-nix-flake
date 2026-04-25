# modules/nixos.nix
#
# NixOS module for the Zephyr SDK.
#
# Usage in a NixOS flake:
#
#   {
#     inputs = {
#       nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
#       zephyr-nix.url = "github:yourorg/zephyr-nix";
#     };
#
#     outputs = { nixpkgs, zephyr-nix, ... }: {
#       nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
#         system  = "x86_64-linux";
#         modules = [
#           zephyr-nix.nixosModules.default
#           {
#             programs.zephyr-sdk = {
#               enable = true;
#               gnu.targets = [ "arm-zephyr-eabi" "riscv64-zephyr-elf" ];
#               llvm.enable = false;
#             };
#           }
#           ./configuration.nix
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
      gnuToolchains = if cfg.gnu.enable then cfg.gnu.targets else [];
      enableLlvm    = cfg.llvm.enable;
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
      gnu
      llvm
      enableShellIntegration
      extraEnv;
  };

  # ------------------------------------------------------------------ #
  #  Configuration                                                      #
  # ------------------------------------------------------------------ #
  config = mkIf cfg.enable {

    # Install the SDK into the system profile so it is on PATH for all users.
    environment.systemPackages = impl.packages;

    # System-wide environment variables consumed by CMake / west.
    environment.sessionVariables = impl.sessionVariables;

    # Source zephyrrc in every user's interactive shell via /etc/profile.d.
    environment.etc."profile.d/zephyr-sdk.sh".text = impl.shellInitExtra;

    # udev rules for Zephyr-supported debug probes (J-Link, CMSIS-DAP, etc.)
    # The SDK ships rules under lib/udev/rules.d/ inside the versioned subdir.
    services.udev.packages = [ resolvedPackage ];
  };
}
