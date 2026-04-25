# Nix flake for zephyr-sdk

A Nix flake that packages the [Zephyr SDK](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html) and exposes it as a declarative module for **NixOS**, **home-manager**, and **nix-darwin**.

> **Status:** Early development.

---

## Supported platforms

| Nix system         | Zephyr SDK tarball            |
|--------------------|-------------------------------|
| `x86_64-linux`     | `zephyr-sdk-*_linux-x86_64`   |
| `aarch64-linux`    | `zephyr-sdk-*_linux-aarch64`  |
| `aarch64-darwin`   | `zephyr-sdk-*_macos-aarch64`  |

---

## Quickstart

### 1. NixOS (`nixosConfigurations`)

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
    zephyr-nix.url = "github:yourorg/zephyr-nix";
  };

  outputs = { nixpkgs, zephyr-nix, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      system  = "x86_64-linux";
      modules = [
        zephyr-nix.nixosModules.default
        {
          programs.zephyr-sdk = {
            enable = true;
            gnu.targets = [ "arm-zephyr-eabi" "riscv64-zephyr-elf" ];
            # llvm.enable = true;
          };
        }
        ./configuration.nix
      ];
    };
  };
}
```

### 2. home-manager (standalone)

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    zephyr-nix.url   = "github:yourorg/zephyr-nix";
  };

  outputs = { home-manager, zephyr-nix, nixpkgs, ... }: {
    homeConfigurations."alice@myHost" = home-manager.lib.homeManagerConfiguration {
      pkgs    = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        zephyr-nix.homeManagerModules.default
        {
          programs.zephyr-sdk = {
            enable = true;
            gnu.targets = [ "arm-zephyr-eabi" ];
          };
        }
      ];
    };
  };
}
```

It can also be embedded in a NixOS or darwin config that uses the home-manager NixOS/Darwin module:

```nix
home-manager.users.alice = {
  imports = [ zephyr-nix.homeManagerModules.default ];
  programs.zephyr-sdk = {
    enable = true;
    gnu.targets = [ "arm-zephyr-eabi" ];
  };
};
```

### 3. nix-darwin (`darwinConfigurations`)

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url    = "github:NixOS/nixpkgs/nixos-unstable";
    darwin.url     = "github:LnL7/nix-darwin";
    zephyr-nix.url = "github:yourorg/zephyr-nix";
  };

  outputs = { darwin, zephyr-nix, ... }: {
    darwinConfigurations.myMac = darwin.lib.darwinSystem {
      system  = "aarch64-darwin";
      modules = [
        zephyr-nix.darwinModules.default
        {
          programs.zephyr-sdk = {
            enable = true;
            gnu.targets = [ "arm-zephyr-eabi" ];
            # llvm.enable = true;  # macOS users may prefer Clang
          };
        }
        ./darwin-configuration.nix
      ];
    };
  };
}
```

---

## Module options

All three modules expose the same option namespace: `programs.zephyr-sdk.*`

| Option                   | Type              | Default               | Description                                                          |
|--------------------------|-------------------|-----------------------|----------------------------------------------------------------------|
| `enable`                 | `bool`            | `false`               | Install and configure the SDK                                        |
| `package`                | `package\|null`   | `null` (derived)      | Supply a fully custom SDK derivation, bypassing `gnu`/`llvm` options |
| `gnu.enable`             | `bool`            | `true`                | Whether to include GNU toolchain(s)                                  |
| `gnu.targets`            | `[string]\|"all"` | `["arm-zephyr-eabi"]` | GNU toolchain targets to fetch and install                           |
| `llvm.enable`            | `bool`            | `false`               | Whether to include the LLVM toolchain bundle                         |
| `enableShellIntegration` | `bool`            | `true`                | Export `ZEPHYR_SDK_INSTALL_DIR` and `ZEPHYR_TOOLCHAIN_VARIANT`       |
| `extraEnv`               | `attrs`           | `{}`                  | Additional environment variables (e.g. `ZEPHYR_BASE`)                |

> **Note:** `ZEPHYR_TOOLCHAIN_VARIANT` is always set to `"zephyr"` - it is a
> property of the SDK itself, not a user-configurable option.  The toolchain
> *selection* (which targets to install) is handled by `gnu.targets` and
> `llvm.enable` at Nix evaluation time.

---

## Repository layout

```sh
zephyr-nix/
├── flake.nix                   # Flake entry point
├── pkgs/
│   └── zephyr-sdk/
│       ├── default.nix         # SDK derivation
│       └── toolchains.nix      # Helper to select GNU toolchains
├── modules/
│   ├── nixos.nix               # NixOS module
│   ├── home-manager.nix        # home-manager module
│   └── darwin.nix              # nix-darwin module
└── lib/
    ├── options.nix             # Shared option declarations
    └── implementation.nix      # Shared resolved-config logic
```

---

## Roadmap

- [ ] Expose udev rules as a standalone NixOS option
- [ ] Add a `devShell` output with west + dependencies pre-configured
- [ ] CI with GitHub Actions across all three supported systems
