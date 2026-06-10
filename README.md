# Fumoctl's NixOS Config
### Features
* COSMIC Desktop Environment
* XanMod Kernel
* Virtualization enabled by default (Podman and Qemu/KVM)
* Systemd without userdb
* Sane gaming defaults (Increased nofile limits and vm.max_map_count)
* Quad9 DNS over TLS ONLY

### Prerequisites
* NixOS Installed (Minimal or COSMIC Preferred to avoid Home dir cluttering)
* Replace the ```hardware-configuration.nix``` for the one generated when you installed NixOS (usually on ```/etc/nixos```)

## Usage
### Switch to config
```
cd FumoNix
sudo nixos-rebuild boot --flake .#fumonix
```

### Update
```
cd FumoNix
sudo nix flake update
sudo nixos-rebuild switch --flake .#fumonix
```
