# Fumoctl's NixOS Config (FumoNix)

A modular, flake-based NixOS configuration featuring declarative disk partitioning, system-wide theming, hardened security, and gaming/productivity optimizations.

---

## 📸 Screenshots

<img width="2560" height="1600" alt="Screenshot_20260906_222007" src="https://github.com/user-attachments/assets/03ef3559-ab04-4e81-9c75-dc025d04be39" />
<img width="2560" height="1600" alt="Screenshot_20260906_222645" src="https://github.com/user-attachments/assets/e33dcddb-e479-4e5c-b5b7-94fc15fa87d0" />
<img width="2560" height="1600" alt="Screenshot_20260906_222929" src="https://github.com/user-attachments/assets/dc856a55-7c37-401a-9bbf-574296fdbb2c" />



---

## 💻 Hosts

| Host | Description | CPU / Architecture | GPU | Boot / SecureBoot |
| :--- | :--- | :--- | :--- | :--- |
| **`fumonix-desktop`** | Main Workstation | AMD Ryzen (Zen 4) | AMD Radeon | Limine with SecureBoot |
| **`fumonix-laptop`** | Tuxedo InfinityBook Max 15 Gen 10 | AMD Ryzen (Zen 4) | AMD Radeon + NVIDIA RTX (PRIME Offload) | Limine with SecureBoot |

---

## 🌟 Features

### 🎨 Theming & Styling
- **[Stylix](file:///home/fumoctl/FumoNix/hosts/common/stylix.nix)**: Coordinated system-wide dark theme based on **Tokyo Night Dark** (`base16-schemes`).
- **Display Manager**: SDDM customized with the **Catppuccin Mocha Mauve** theme (`catppuccin-sddm`) with Qt multimedia & SVG support.
- **Bootloader**: Themed Limine bootloader via Stylix.
- **Typography & Cursors**: JetBrainsMono Nerd Font, Noto Sans/Serif CJK JP, Noto Color Emoji, and `Bibata-Modern-Ice` cursors.
- **Integrated Toolkits**: Cohesive theming across KDE Plasma 6, GTK, and Flatpak applications.

### 🖥️ Desktop & Ergonomics
- **Desktop Environment**: Declaratively configured **KDE Plasma 6** (Wayland) via [`plasma-manager`](file:///home/fumoctl/FumoNix/hosts/common/home.nix).
- **Panel & Layout**: Floating bottom panel with NixOS Kickoff launcher, icon tasks, pager, 4 virtual desktops, 24h clock with custom date formatting (`dd/MM/yyyy`), and system tray.
- **Window Management**: `FocusFollowsMouse` policy with zero delay.
- **Default Terminal**: **Ptyxis** terminal emulator integrated into KDE globals with session restore disabled.
- **Default Applications**: Comprehensive XDG MIME mappings for Brave, VS Code, Thunderbird, Gwenview, Elisa, MPV/umpv, Okular, and Dolphin.
- **Input Tuning**: Flat mouse acceleration profile (1:1 direct tracking).

### ⚡ Kernel & Hardware Performance
- **Optimized Kernel**: CachyOS Zen 4 LTO kernel (`linuxPackages_cachyos-lto-znver4`) sourced from **Chaotic-Nyx** (`nyxpkgs-unstable`) binary cache.
- **Wine Synchronization**: `ntsync` kernel module enabled for high-performance Wine/Proton thread synchronization.
- **System Tuning**: `vm.max_map_count = 2147483642` (SteamOS default) and maximum `nofile` pam/systemd limits (1048576).
- **Laptop Hardware**: Tuxedo drivers (`tuxedo-drivers` with custom pahole override for CachyOS kernels) and Tailor GUI (`tailor-gui`).
- **NVIDIA Hybrid Graphics**: Open NVIDIA kernel modules (`nvidia_cachyos-lto`) with PRIME offload (`nvidia-offload`).

### 🎮 Gaming
- **Steam**: Configured with 32-bit graphics support, firewall rules for Steam Remote Play, and custom Proton compatibility tools:
  - `proton-cachyos_x86_64_v3`
  - `proton-ge-custom`
- **Performance & Monitoring**: MangoHud, Goverlay, GameMode, and Gamescope session support.
- **GPU Control**: LACT daemon and GUI for AMDGPU fan curves, monitoring, and overclocking.
- **Frame Generation**: Lossless Scaling Vulkan layer (`lsfg-vk`) and UI (`lsfg-vk-ui`).

### 🔒 Security & Hardened Networking
- **DNS-over-TLS & DNSSEC**: Native **`systemd-resolved`** configuration enforcing DNS-over-TLS and DNSSEC with AdGuard DNS (`dns.adguard-dns.com`).
- **Network Privacy**: NetworkManager configured with MAC address randomization (`stable-temporary` for Wi-Fi and Ethernet) and IPv6 privacy extensions (`ip6-privacy = 2`).
- **Firewall**: Modern `nftables` firewall with selective ports for KDE Connect (1714–1764 TCP/UDP) and Steam.
- **Captive Portals**: `captive-browser` integrated for public networks on laptop.
- **Hardened Firefox**: Enterprise policy profile locking down all telemetry/studies, enforcing Brave Search, and force-installing uBlock Origin, Multi-Account Containers, and Cookie AutoDelete.
- **Brave Browser**: Configured with Proton Pass, Plasma Integration, Decentraleyes, and Privacy Badger.

### 💾 Storage & Virtualization
- **Declarative Partitioning**: Automated GPT partitioning, LUKS2 encryption, and Btrfs subvolumes (`@`, `@home`, `@nix`, `@log`, `@snapshots`, `@swap`) via **Disko**.
- **Containers**: Rootless **Podman** configuration with Docker CLI alias, Docker socket compatibility, Podman Desktop, Podman TUI, and declarative OCI container definitions.
- **Virtualization**: QEMU/KVM via `libvirtd` with TPM emulation (`swtpm`), `virtiofsd` shared folders, and SPICE clipboard integration.
- **Package Management**: Nix Flakes, Home Manager, Flatpak management via `nix-flatpak` with scheduled daily updates, and `nix-ld` for running unpatched dynamic binaries.

---

## 🚀 Installation Guide

### Option A: Installing an Existing Host (`fumonix-desktop` or `fumonix-laptop`)

1. **Boot into the NixOS Live USB**.
2. **Verify target disk ID**:
   Ensure the disk ID in [hosts/desktop/disko.nix](file:///home/fumoctl/FumoNix/hosts/desktop/disko.nix) or [hosts/laptop/disko.nix](file:///home/fumoctl/FumoNix/hosts/laptop/disko.nix) matches your target drive:
   ```bash
   ls -l /dev/disk/by-id/
   ```
3. **Partition, format, and mount with Disko**:

   For Desktop:
   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake github:fumoctl/FumoNix#fumonix-desktop
   ```

   For Laptop:
   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake github:fumoctl/FumoNix#fumonix-laptop
   ```

   _(Or clone the repo locally and use `--flake .#<hostname>`)_

4. **Install NixOS**:

   ```bash
   sudo nixos-install --flake github:fumoctl/FumoNix#<hostname>
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
