{ config
, lib
, pkgs
, ...
}:

{
  # ============================================================================
  # 1. MODULE IMPORTS
  # ============================================================================
  imports = [
    # Shared system-wide baseline configuration
    ../common/default.nix

    # Auto-detected hardware definitions (CPU microcode, initrd kernel modules)
    ./hardware-configuration.nix

    # Declarative NVMe storage layout, LUKS2 encryption, and Btrfs subvolumes
    ./disko.nix

    # Podman container runtime, OCI containers, and Kubernetes CLI tools
    ./containers.nix
  ];

  # ============================================================================
  # 2. HOST IDENTITY & NETWORKING
  # ============================================================================
  networking.hostName = "fumonix-desktop";

  # ============================================================================
  # 3. BOOTLOADER & SECURE BOOT
  # ============================================================================
  boot.loader.limine = {
    # Enable Secure Boot validation through Limine (managed via sbctl keys)
    secureBoot.enable = true;
  };

  # ============================================================================
  # 4. KERNEL & HARDWARE OPTIMIZATION
  # ============================================================================
  # CachyOS Linux kernel compiled with Link-Time Optimization (LTO) and targeted
  # specifically for the AMD Zen 4 architecture (znver4). Unlocks AVX-512 extensions,
  # optimized cache layouts, and the BORE (Burst-Oriented Response Enhancer) CPU scheduler.
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

  # Low-level Linux kernel boot parameters
  boot.kernelParams = [
    # Disables AMDGPU runtime power management (runpm=0) to eliminate audio stutter over
    # DisplayPort/HDMI, micro-freezes, and PCIe link wake latency on desktop AMD GPUs
    "amdgpu.runpm=0"
  ];

  # ============================================================================
  # 5. SYSTEM STATE VERSION
  # ============================================================================
  # Defines the initial NixOS release version for stateful data and defaults.
  # Do not change this after initial install.
  system.stateVersion = "26.05";
}
