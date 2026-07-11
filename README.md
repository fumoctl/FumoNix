# Fumoctl's NixOS Config

### Features

- KDE Plasma
- XanMod Kernel
- Virtualization enabled by default (Podman and Qemu/KVM)
- Systemd without userdb
- Sane gaming defaults (Increased nofile limits and vm.max_map_count)
- Adguard DNS over TLS ONLY
- Hardened Firefox
- Modular config for multiple hosts

### Prerequisites

- NixOS Installed (Minimal or KDE Preferred to avoid Home dir cluttering)
- Replace the `hardware-configuration.nix` for the one generated when you installed NixOS (usually on `/etc/nixos`)

## Usage

### Switch to config

```
cd FumoNix
sudo nixos-rebuild boot --flake .#fumonix-<hostname>
```

### Update

```
cd FumoNix
sudo nix flake update
sudo nixos-rebuild switch --flake .#fumonix-<hostname>
```
