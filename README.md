# Zephyr SDK Flake

A Nix flake for [Zephyr SDK](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html).

This flake provides a development environment with the Zephyr SDK and all required host tools.

## Usage

### 1. Direct use

Enter a shell with the default minimal SDK:

```bash
nix develop github:EncryptedCicada/zephyr-sdk-nix-flake
```

### 2. Integration in your project

Create a `flake.nix` in your Zephyr project:

```nix
{
  inputs = {
    nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
    zephyr-nix.url = "github:EncryptedCicada/zephyr-sdk-nix-flake";
  };

  outputs = { self, nixpkgs, zephyr-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = zephyr-nix.devShells.${system}.zephyr.override {
        zephyrSdk = zephyr-nix.packages.${system}.zephyr-sdk.override {
          gnuToolchains = [ "arm-zephyr-eabi" "xtensa-espressif_esp32s3_zephyr-elf" ];
        };
      };
    };
}
```

Then enter the shell:

```bash
nix develop
```

## Features

- **Single Shell**: The `zephyr` devShell includes all host dependencies (`cmake`, `ninja`, `west`, etc.).
- **Overridable**: Easily customize which GNU toolchains are included in the SDK.
- **Flattened SDK**: The SDK installs directly into `$out` for reliable discovery.
- **Python 3.12 support**: Correctly patched GDB dependencies for NixOS.
