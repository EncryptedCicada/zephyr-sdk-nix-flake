# modules/nixos.nix
#
# NixOS module for the Zephyr SDK.
#
# Usage in a NixOS flake:
#
#   {
#     inputs.zephyr-nix.url = "github:yourorg/zephyr-nix";
#
#     outputs = { nixpkgs, zephyr-nix, ... }: {
#       nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
#         modules = [
#           zephyr-nix.nixosModules.default
#           {
#             programs.zephyr-sdk.enable = true;
#             # programs.zephyr-sdk.toolchainVariant = "gnuarmemb";
#           }
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
  impl        = import ../lib/implementation.nix { inherit lib cfg pkgs; };
in
{
  # ------------------------------------------------------------------ #
  #  Option declarations                                                #
  # ------------------------------------------------------------------ #
  options.programs.zephyr-sdk = with lib; {
    inherit (optionDecls)
      enable
      package
      enableShellIntegration
      toolchainVariant
      extraEnv;
  };

  # ------------------------------------------------------------------ #
  #  Configuration                                                      #
  # ------------------------------------------------------------------ #
  config = mkIf cfg.enable {

    # Install the SDK into the system profile so it is on PATH for every user.
    environment.systemPackages = impl.packages;

    # System-wide environment variables consumed by CMake / west.
    environment.sessionVariables = impl.sessionVariables;

    # Source the zephyrrc in every user's interactive shell via
    # /etc/profile.d (bash/zsh) or the equivalent.
    environment.etc."profile.d/zephyr-sdk.sh".text = impl.shellInitExtra;

    # udev rules for Zephyr-supported debug probes (J-Link, OpenOCD, etc.)
    # Only relevant on Linux; harmless to gate explicitly.
    services.udev.packages = lib.optionals (pkgs.stdenv.isLinux) [
      cfg.package
    ];
  };
}
