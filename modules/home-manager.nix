# modules/home-manager.nix
#
# home-manager module for the Zephyr SDK.
#
# Usage as a standalone home-manager flake module:
#
#   {
#     inputs = {
#       home-manager.url  = "github:nix-community/home-manager";
#       zephyr-nix.url    = "github:yourorg/zephyr-nix";
#     };
#
#     outputs = { home-manager, zephyr-nix, ... }: {
#       homeConfigurations."alice" = home-manager.lib.homeManagerConfiguration {
#         modules = [
#           zephyr-nix.homeManagerModules.default
#           {
#             programs.zephyr-sdk.enable = true;
#           }
#         ];
#       };
#     };
#   }
#
# The module can also be composed inside a NixOS or nix-darwin config that
# already imports home-manager as a NixOS / Darwin module:
#
#   home-manager.users.alice = {
#     imports = [ zephyr-nix.homeManagerModules.default ];
#     programs.zephyr-sdk.enable = true;
#   };

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

    # Add the SDK to the user's profile.
    home.packages = impl.packages;

    # Per-user session variables (written to ~/.profile, ~/.bash_profile,
    # etc. depending on the shell modules that are also enabled).
    home.sessionVariables = impl.sessionVariables;

    # Source the zephyrrc in interactive shells.
    # home-manager exposes per-shell init hooks; we use the generic one.
    home.sessionVariablesExtra = impl.shellInitExtra;
  };
}
