# modules/darwin.nix
#
# nix-darwin module for the Zephyr SDK.
#
# Usage in a nix-darwin flake:
#
#   {
#     inputs = {
#       darwin.url     = "github:LnL7/nix-darwin";
#       zephyr-nix.url = "github:yourorg/zephyr-nix";
#     };
#
#     outputs = { darwin, zephyr-nix, ... }: {
#       darwinConfigurations.myMac = darwin.lib.darwinSystem {
#         modules = [
#           zephyr-nix.darwinModules.default
#           {
#             programs.zephyr-sdk.enable = true;
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

    # Install the SDK into the system profile.
    environment.systemPackages = impl.packages;

    # nix-darwin exposes launchd environment variables and
    # /etc/zshenv / /etc/bashrc for shell init.
    environment.variables = impl.sessionVariables;

    # Source zephyrrc in interactive shells via /etc/zshrc (default shell
    # on macOS is zsh) and /etc/bashrc.
    programs.zsh.shellInit = lib.mkAfter impl.shellInitExtra;
    programs.bash.shellInit = lib.mkAfter impl.shellInitExtra;
  };
}
