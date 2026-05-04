{
  description = "Zephyr SDK development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = forAllSystems (system:
        import nixpkgs { inherit system; }
      );
    in
    {
      packages = forAllSystems (system: {
        zephyr-sdk     = pkgsFor.${system}.callPackage ./pkgs/zephyr-sdk { };
        default        = self.packages.${system}.zephyr-sdk;
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
