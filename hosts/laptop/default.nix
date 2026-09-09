{ config
, lib
, pkgs
, ...
}:

# ==============================================================================
# HOST CONFIGURATION: Tuxedo InfinityBook Max 15 - Gen10 - AMD
# ==============================================================================

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
  networking.hostName = "fumonix-laptop";

  # Captive portal login helper: launches a dedicated ephemeral browser instance
  # to authenticate through public Wi-Fi (airports, hotels, cafes) without exposing
  # main browser sessions or DNS settings
  programs.captive-browser = {
    enable = true;
    interface = "wlp98s0"; # Wireless network interface name
  };

  # ============================================================================
  # 3. BOOTLOADER
  # ============================================================================
  boot.loader.limine = {
    # Secure Boot disabled on laptop
    secureBoot.enable = false;
  };

  # ============================================================================
  # 4. KERNEL & HARDWARE OVERRIDES
  # ============================================================================
  # CachyOS Linux kernel compiled with Link-Time Optimization (LTO) for AMD Zen 4.
  # Extended to build tuxedo-drivers with pahole to ensure BTF type information
  # is correctly generated during module compilation.
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4.extend (final: prev: {
    tuxedo-drivers = prev.tuxedo-drivers.override { pahole = pkgs.pahole; };
  });

  # ============================================================================
  # 5. DUAL-GPU HYBRID GRAPHICS (AMD RADEON IGPU + NVIDIA DGPU PRIME)
  # ============================================================================
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Enable kernel modesetting (required for Wayland compositors and KMS)
    modesetting.enable = true;

    # Use NVIDIA open-source kernel modules (recommended for Turing architecture and newer)
    open = true;

    # CachyOS LTO optimized proprietary driver package
    package = pkgs.nvidia_cachyos-lto;

    # Power management: allows the discrete GPU to enter deep sleep/RTD3 when idle
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # NVIDIA X Server Settings GUI tool
    nvidiaSettings = true;

    # PRIME Render Offload: keeps the dGPU fully suspended until explicitly launched
    # with the 'nvidia-offload' wrapper script, maximizing laptop battery life
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Generates 'nvidia-offload' wrapper command
      };
      # Hardware PCI bus IDs (verified via 'lspci')
      amdgpuBusId = "PCI:66:0:0"; # Integrated AMD Radeon graphics
      nvidiaBusId = "PCI:64:0:0"; # Discrete NVIDIA GeForce RTX graphics
    };
  };

  # ============================================================================
  # 6. TUXEDO HARDWARE INTEGRATION
  # ============================================================================
  # Kernel modules for Tuxedo laptop fan control, keyboard backlight, and power profiles
  hardware.tuxedo-drivers.enable = true;

  # Tuxedo Control Center daemon and GUI (tailor-gui) for hardware management
  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # ============================================================================
  # 7. SYSTEM STATE VERSION
  # ============================================================================
  # Defines the initial NixOS release version for stateful data and defaults.
  # Do not change this after initial install.
  system.stateVersion = "26.05";
}
