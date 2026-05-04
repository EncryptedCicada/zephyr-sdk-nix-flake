{
  description = "Zephyr SDK development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "segger-jlink"
                "nrfutil"
                "nrfutil-completion"
                "nrfutil-device"
                "nrfutil-trace"
                "nrfutil-ble-sniffer"
                "nrf-udev"
              ];
            segger-jlink.acceptLicense = true;
            permittedInsecurePackages = [
              "segger-jlink-qt4-874"
            ];
          };
        }
      );
    in
    {
      packages = forAllSystems (system: {
        zephyr-sdk = pkgsFor.${system}.callPackage ./pkgs/zephyr-sdk { };
        default = self.packages.${system}.zephyr-sdk;
      });

      devShells = forAllSystems (system: {
        # The 'zephyr' shell allows users to override toolchains etc via overriding the sdk package
        zephyr = pkgsFor.${system}.callPackage ./shells/zephyr.nix {
          zephyrSdk = self.packages.${system}.zephyr-sdk;
        };

        default = self.devShells.${system}.zephyr;
      });

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt);
    };
}
