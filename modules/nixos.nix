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
#               toolchain.gnu.enable     = true;
#               toolchain.gnu.toolchains = [ "arm-zephyr-eabi" "riscv64-zephyr-elf" ];
#               # toolchain.llvm.enable = true;
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

    udev.enable = mkOption {
      type        = types.bool;
      default     = true;
      description = ''
        Whether to install udev rules for Zephyr debug probes (OpenOCD,
        J-Link, CMSIS-DAP, etc.) via {option}`services.udev.packages`.
        When enabled, board flashing works for regular users without sudo.
        Disable if you manage udev rules through another mechanism.
      '';
    };
  };

  # ------------------------------------------------------------------ #
  #  Configuration                                                      #
  # ------------------------------------------------------------------ #
  config = mkIf cfg.enable {

    # Install the SDK into the system profile so it is on PATH for all users.
    environment.systemPackages = impl.packages;

    # System-wide environment variables consumed by CMake / west.
    environment.sessionVariables = impl.sessionVariables;

    # udev rules for Zephyr debug probes (OpenOCD, J-Link, CMSIS-DAP, …).
    # The package installs all *.rules files it finds into $out/lib/udev/rules.d/
    # so NixOS picks them up automatically here.
    services.udev.packages = mkIf cfg.udev.enable [ resolvedPackage ];
  };
}
