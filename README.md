# Fumoctl's NixOS Config (FumoNix)

A modular, flake-based NixOS configuration featuring declarative disk partitioning, hardened security, and gaming/productivity optimizations.

---

## 🌟 Features

- **Desktop Environment**: KDE Plasma 6 (via Wayland) with SDDM.
- **Bootloader**: Limine Bootloader with SecureBoot support.
- **Declarative Partitioning**: [Disko](https://github.com/nix-community/disko) for automated GPT, LUKS2 encryption, Btrfs subvolumes, and swap setup.
- **Kernel**: CachyOS Kernel with architecture optimizations and performance tweaks (`vm.max_map_count` and `nofile` limits tuned for gaming).
- **Hardened Networking & DNS**: AdGuard DNS-over-TLS only via Unbound, nftables, MAC address randomization.
- **Hardened Firefox**: Enterprise policy profile with telemetry completely disabled, uBlock Origin, Multi-Account Containers, and privacy enhancements.
- **Virtualization**: Podman, Docker, and QEMU/KVM (`libvirtd`) with TPM emulation (`swtpm`) and virtiofs.
- **Package Management**: Home Manager, Flakes, Flatpak integration (`nix-flatpak`), and nix-ld for unpatched binaries.

---

## 🚀 Installation Guide

### Option A: Installing an Existing Host (`fumonix-desktop` example)

1. **Boot into the NixOS Live USB**.
2. **Verify target disk ID**:
   Ensure the disk ID in [hosts/desktop/disko.nix](file:///home/fumoctl/FumoNix/hosts/desktop/disko.nix) matches your target drive:
   ```bash
   ls -l /dev/disk/by-id/
   ```
3. **Partition, format, and mount with Disko**:

   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake github:fumoctl/FumoNix#fumonix-desktop
   ```

   _(Or clone the repo locally and use `--flake .#fumonix-desktop`)_

4. **Install NixOS**:

   ```bash
   sudo nixos-install --flake github:fumoctl/FumoNix#fumonix-desktop
   ```

5. **Reboot**:
   ```bash
   reboot
   ```

---

### Option B: Bootstrapping a Brand New Host

1. **Boot into the NixOS Live USB** on the target machine.
2. **Generate hardware configuration (without storage mounts)**:
   ```bash
   nixos-generate-config --no-filesystems --show-hardware-config
   ```
   _(The `--no-filesystems` flag avoids hardcoding mounts and UUIDs since Disko manages storage)._
3. **Create the new host configuration**:
   - Create `hosts/<hostname>/`:
     - `hardware-configuration.nix` (paste the output from step 2).
     - `disko.nix` (specify the target disk ID and partition scheme).
     - `containers.nix` (host-specific container and Podman configuration).
     - `default.nix` (import `../common/default.nix`, `./hardware-configuration.nix`, `./disko.nix`, and `./containers.nix`).
   - Add the host definition under `nixosConfigurations.<hostname>` in [flake.nix](file:///home/fumoctl/FumoNix/flake.nix).
4. **Partition and Install**:
   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake .#<hostname>
   sudo nixos-install --flake .#<hostname>
   reboot
   ```

---

## 🛠️ Post-Install & Daily Usage

### Rebuild and Switch Configuration

```bash
cd FumoNix
sudo nixos-rebuild switch --flake .#fumonix-<hostname>
```

### Test Configuration (Boot Only)

```bash
sudo nixos-rebuild boot --flake .#fumonix-<hostname>
```

### Update Flake Inputs

```bash
cd FumoNix
nix flake update
sudo nixos-rebuild switch --flake .#fumonix-<hostname>
```
