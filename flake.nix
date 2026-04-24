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
      # Systems the Zephyr SDK officially supports
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper to produce an attrset over all supported systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Instantiate nixpkgs for each system
      pkgsFor = forAllSystems (system:
        import nixpkgs { inherit system; }
      );
    in
    {
      # ------------------------------------------------------------------ #
      #  Packages                                                           #
      # ------------------------------------------------------------------ #
      packages = forAllSystems (system: {
        zephyr-sdk = pkgsFor.${system}.callPackage ./pkgs/zephyr-sdk { };
        default    = self.packages.${system}.zephyr-sdk;
      });

      # ------------------------------------------------------------------ #
      #  NixOS module                                                       #
      # ------------------------------------------------------------------ #
      nixosModules = {
        zephyr-sdk = import ./modules/nixos.nix { inherit self; };
        default    = self.nixosModules.zephyr-sdk;
      };

      # ------------------------------------------------------------------ #
      #  home-manager module                                                #
      # ------------------------------------------------------------------ #
      homeManagerModules = {
        zephyr-sdk = import ./modules/home-manager.nix { inherit self; };
        default    = self.homeManagerModules.zephyr-sdk;
      };

      # ------------------------------------------------------------------ #
      #  nix-darwin module                                                  #
      # ------------------------------------------------------------------ #
      darwinModules = {
        zephyr-sdk = import ./modules/darwin.nix { inherit self; };
        default    = self.darwinModules.zephyr-sdk;
      };

      # ------------------------------------------------------------------ #
      #  Formatter                                                          #
      # ------------------------------------------------------------------ #
      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-rfc-style);
    };
}
