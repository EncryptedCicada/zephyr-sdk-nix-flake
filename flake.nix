{
  description = "Zephyr SDK packaging and modules for NixOS, nix-darwin, and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager — users should override this with their own input
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin — only required for macOS users
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }:
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
        zephyr-sdk = pkgsFor.${system}.callPackage ./pkgs/zephyr-sdk { };
        default    = self.packages.${system}.zephyr-sdk;
      });

      devShells = forAllSystems (system: {
        default = import ./shells/zephyr.nix {
          pkgs      = pkgsFor.${system};
          zephyrSdk = self.packages.${system}.zephyr-sdk;
        };
      });

      nixosModules = {
        zephyr-sdk = import ./modules/nixos.nix { inherit self; };
        default    = self.nixosModules.zephyr-sdk;
      };

      homeManagerModules = {
        zephyr-sdk = import ./modules/home-manager.nix { inherit self; };
        default    = self.homeManagerModules.zephyr-sdk;
      };

      darwinModules = {
        zephyr-sdk = import ./modules/darwin.nix { inherit self; };
        default    = self.darwinModules.zephyr-sdk;
      };

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt);
    };
}
