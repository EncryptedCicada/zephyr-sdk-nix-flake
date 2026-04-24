# lib/implementation.nix
#
# Returns the concrete Nix values that every module type (NixOS, darwin,
# home-manager) derives its config from.  Keeping this centralised means
# behaviour stays in sync across all three module back-ends.

{ lib, cfg, pkgs }:

let
  sdkOut = cfg.package;

  # The environment variables that must be set for west / CMake to work.
  coreEnv = {
    ZEPHYR_SDK_INSTALL_DIR    = "${sdkOut}";
    ZEPHYR_TOOLCHAIN_VARIANT  = cfg.toolchainVariant;
  };

  allEnv = lib.mkMerge [
    (lib.mkIf cfg.enableShellIntegration coreEnv)
    cfg.extraEnv
  ];
in
{
  # Package list to install
  packages = [ sdkOut ];

  # Flat attrset of env-var name → value
  sessionVariables = allEnv;

  # A shell snippet that can be sourced in an interactive shell to add
  # any SDK-provided host tools (e.g. west, pyocd wrappers) to PATH.
  shellInitExtra = lib.optionalString cfg.enableShellIntegration ''
    # ---- zephyr-sdk shell init (managed by nix) ----
    if [ -f "${sdkOut}/share/zephyr-sdk/zephyrrc" ]; then
      source "${sdkOut}/share/zephyr-sdk/zephyrrc"
    fi
  '';
}
