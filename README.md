# zephyr-nix

A Nix flake that packages the [Zephyr SDK](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html) and exposes it as a declarative module for **NixOS**, **home-manager**, and **nix-darwin**.

> **Status:** Early development.  The SHA-256 hashes in `pkgs/zephyr-sdk/default.nix` are placeholders (`lib.fakeSha256`) and must be filled in before the package can be built.  ELF patching for NixOS is scaffolded but will require iteration against the actual SDK binaries.

---

## Supported platforms

| Nix system         | Zephyr SDK tarball            |
|--------------------|-------------------------------|
| `x86_64-linux`     | `zephyr-sdk-*_linux-x86_64`   |
| `aarch64-linux`    | `zephyr-sdk-*_linux-aarch64`  |
| `aarch64-darwin`   | `zephyr-sdk-*_macos-aarch64`  |

---

## Quickstart

### 1 — NixOS (`nixosConfigurations`)

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
          programs.zephyr-sdk.enable = true;
          # programs.zephyr-sdk.toolchainVariant = "gnuarmemb";
        }
        ./configuration.nix
      ];
    };
  };
}
```

### 2 — home-manager (standalone)

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
          programs.zephyr-sdk.enable = true;
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
  programs.zephyr-sdk.enable = true;
};
```

### 3 — nix-darwin (`darwinConfigurations`)

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
          programs.zephyr-sdk.enable = true;
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

| Option                              | Type      | Default     | Description |
|-------------------------------------|-----------|-------------|-------------|
| `enable`                            | `bool`    | `false`     | Install and configure the SDK |
| `package`                           | `package` | flake pkg   | Override the SDK derivation |
| `enableShellIntegration`            | `bool`    | `true`      | Export `ZEPHYR_SDK_INSTALL_DIR` etc. |
| `toolchainVariant`                  | `string`  | `"zephyr"`  | Value of `ZEPHYR_TOOLCHAIN_VARIANT` |
| `extraEnv`                          | `attrs`   | `{}`        | Additional environment variables |

---

## Getting the real SHA-256 hashes

```bash
# x86_64-linux
nix-prefetch-url \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-x86_64.tar.xz

# aarch64-linux
nix-prefetch-url \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-aarch64.tar.xz

# aarch64-darwin
nix-prefetch-url \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_macos-aarch64.tar.xz
```

Paste each result into the corresponding `sha256 = ...` field in `pkgs/zephyr-sdk/default.nix`.

---

## Repository layout

```
zephyr-nix/
├── flake.nix                   # Flake entry point
├── pkgs/
│   └── zephyr-sdk/
│       └── default.nix         # SDK derivation (fetch + ELF patch + shebang fix)
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

- [ ] Iterate ELF patching against actual SDK binaries on NixOS
- [ ] Support selecting individual toolchain bundles (arm, riscv, xtensa, …)
- [ ] Expose udev rules as a standalone NixOS option
- [ ] Add a `devShell` output with west + dependencies pre-configured
- [ ] CI with GitHub Actions across all three supported systems
