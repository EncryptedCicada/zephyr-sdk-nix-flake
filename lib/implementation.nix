# lib/implementation.nix
#
# Returns the concrete Nix values that every module type (NixOS, darwin,
# home-manager) derives its config from.  Keeping this centralised means
# behaviour stays in sync across all three module back-ends.
#

{ lib, cfg, pkgs, package }:

let
  # package is the *container* directory ($out).
  # The actual SDK tree lives at package/zephyr-sdk-<version>/.
  # Pointing ZEPHYR_SDK_INSTALL_DIR at the container enables Zephyr's
  # automatic multi-SDK version selection (see Zephyr docs).

  # ZEPHYR_TOOLCHAIN_VARIANT is always "zephyr".  It identifies that the
  # Zephyr-bundled cross-compilers are in use — this is a property of the
  # SDK itself, not a user preference.  The user's toolchain selection
  # (which GNU targets, whether to include LLVM) is resolved at Nix
  # evaluation time via the gnu.* / llvm.* options and baked into the
  # package derivation.
  coreEnv = {
    ZEPHYR_SDK_INSTALL_DIR   = "${package}";
    ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
  };

  allEnv = lib.mkMerge [
    (lib.mkIf cfg.enableShellIntegration coreEnv)
    cfg.extraEnv
  ];
in
{
  packages = [ package ];

  sessionVariables = allEnv;

  shellInitExtra = lib.optionalString cfg.enableShellIntegration ''
    # ---- zephyr-sdk shell init (managed by nix) ----
    if [ -f "${package}/share/zephyr-sdk/zephyrrc" ]; then
      source "${package}/share/zephyr-sdk/zephyrrc"
    fi
  '';
}
