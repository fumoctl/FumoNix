{ config
, lib
, pkgs
, inputs
, ...
}:

{
  # ============================================================================
  # 1. MODULE IMPORTS
  # ============================================================================
  imports = [
    # System-wide aesthetic theming (Catppuccin, wallpaper, fonts, GTK/Qt styling)
    ./stylix.nix
  ];

  # ============================================================================
  # 2. NIX PACKAGE MANAGER & FLAKES CONFIGURATION
  # ============================================================================
  nix.settings = {
    # Enable modern Nix CLI commands and Flakes support
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Grant root and all members of the 'wheel' group passwordless Nix daemon trust
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # Allow proprietary/unfree packages globally (e.g. Steam, Chrome, Nvidia/CUDA, Discord)
  nixpkgs.config.allowUnfree = true;

  # Channel and repository overlays
  nixpkgs.overlays = [
    # Expose `pkgs.unstable.<package>` while preserving stable nixpkgs as default
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })

    # Custom external repository overlays
    inputs.antigravity-nix.overlays.default
  ];

  # ============================================================================
  # 3. BOOTLOADER & KERNEL SUBSYSTEM
  # ============================================================================
  boot = {
    # Modern, lightweight, multiprotocol Limine bootloader
    loader = {
      limine.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Kernel modules loaded at boot:
    # - ntsync: Fast Windows NT synchronization primitives driver (Wine/Proton mutex/event acceleration)
    kernelModules = [ "ntsync" ];

    # Low-level Linux kernel sysctl tuning
    kernel.sysctl = {
      # SteamOS default: prevents out-of-memory crashes in memory-heavy games (e.g., Star Citizen, Hogwarts Legacy)
      "vm.max_map_count" = 2147483642;
    };
  };

  # ============================================================================
  # 4. SECURITY & SYSTEM RESOURCE LIMITS
  # ============================================================================
  # Raise file descriptor limits system-wide to prevent "Too many open files" errors
  # under heavy multi-threading, Wine/Proton handles, and container runtimes
  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576";

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-"; # "-" sets both soft and hard limits simultaneously
      item = "nofile";
      value = "1048576";
    }
  ];

  # Disable systemd-userdbd to prevent Varlink IPC overhead and user lookup stalls/delays
  systemd.package = pkgs.systemd.override { withUserDb = false; };
  services.userdbd.enable = lib.mkForce false;

  # ============================================================================
  # 5. NETWORKING, FIREWALL & ENCRYPTED DNS
  # ============================================================================
  networking = {
    # Use modern Linux nftables instead of legacy iptables
    nftables.enable = true;

    networkmanager = {
      enable = true;
      # Delegate DNS resolution strictly to systemd-resolved
      dns = "systemd-resolved";
      settings = {
        main = {
          dns = "systemd-resolved";
        };
        connection = {
          # Ignore DHCP-provided DNS to prevent DNS leaks and ISP override
          "ipv4.ignore-auto-dns" = true;
          "ipv6.ignore-auto-dns" = true;

          # Privacy: Use stable pseudo-random MAC addresses per network SSID/connection
          "wifi.cloned-mac-address" = "stable-temporary";
          "ethernet.cloned-mac-address" = "stable-temporary";

          # IPv6 Privacy Extensions (RFC 4941): generate temporary outbound addresses
          "ipv6.ip6-privacy" = 2;
        };
        device = {
          # Wi-Fi probe privacy: randomize MAC during network discovery scans
          "wifi.scan-rand-mac-address" = "yes";
        };
      };
    };

    firewall = {
      enable = true;
      # Ports 1714-1764 TCP/UDP for KDE Connect pairing, notification sync, and file transfer
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };

  # Disable unbound DNS resolver in favor of systemd-resolved
  services.unbound.enable = false;

  # DNS-over-TLS (DoT) via AdGuard DNS with DNSSEC validation
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        dnssec = "true";
        dnsovertls = "true";
        DNS = [
          "94.140.14.14#dns.adguard-dns.com"
          "94.140.15.15#dns.adguard-dns.com"
          "2a10:50c0::ad1:ff#dns.adguard-dns.com"
          "2a10:50c0::ad2:ff#dns.adguard-dns.com"
        ];
        fallbackDns = [
          "94.140.14.14#dns.adguard-dns.com"
          "94.140.15.15#dns.adguard-dns.com"
          "2a10:50c0::ad1:ff#dns.adguard-dns.com"
          "2a10:50c0::ad2:ff#dns.adguard-dns.com"
        ];
        # "~." designates these encrypted servers as the default routing domain for all lookups
        Domains = [ "~." ];
      };
    };
  };

  # ============================================================================
  # 6. HARDWARE, GRAPHICS & PERIPHERALS
  # ============================================================================
  # Bluetooth controller configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Power on adapter on boot
  };

  # Graphics driver infrastructure (Mesa / Vulkan / VA-API)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit graphics drivers required for Steam and Wine games
    extraPackages = [
      # Vulkan layer implementing Lossless Scaling frame generation on Linux
      pkgs.unstable.lsfg-vk
    ];
  };

  # GPU Daemon: Overclocking, fan curve control, and power profile management
  services.lact.enable = true;

  # Power profiles daemon for dynamic CPU power/governor state switching
  services.power-profiles-daemon.enable = true;
  hardware.system76.enableAll = false;

  # Input device tuning (libinput)
  services.libinput = {
    enable = true;
    mouse = {
      # "flat" completely disables acceleration for true 1:1 raw hardware sensor tracking
      accelProfile = "flat";
      # accelSpeed = "0"; # Optional sensitivity adjustment (-1.0 to 1.0)
    };
  };

  # ============================================================================
  # 7. AUDIO SUBSYSTEM (PIPEWIRE & REALTIME AUDIO)
  # ============================================================================
  # RealtimeKit system service: grants PipeWire threads real-time priority (SCHED_RR) to prevent stutter/dropouts
  security.rtkit.enable = true;

  # Disable legacy PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # PipeWire low-latency multimedia routing framework
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # 32-bit ALSA support for older Wine/Steam games
    pulse.enable = true;      # PulseAudio replacement emulation
    jack.enable = true;       # JACK audio API emulation for professional audio software
  };

  # ============================================================================
  # 8. LOCALIZATION, TIME & TYPOGRAPHY
  # ============================================================================
  # Location-based automatic timezone detection
  services.automatic-timezoned.enable = true;

  # System locales
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ]; # Japanese locale for CJK compatibility
  };

  # Keyboard layout settings (X11 & Wayland compositors)
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "altgr-intl"; # US International with AltGr dead keys
    };
  };

  # Typography and font configuration
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      # CJK & Japanese typography
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      ipafont
      kochi-substitute

      # Standard metric-compatible fonts
      liberation_ttf

      # Developer Nerd Fonts (icons & programming glyphs)
      nerd-fonts.symbols-only
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu
      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
  };

  # ============================================================================
  # 9. DESKTOP ENVIRONMENT & DISPLAY MANAGER (KDE PLASMA 6 / SDDM)
  # ============================================================================
  # KDE Plasma 6 Wayland desktop environment
  services.desktopManager.plasma6.enable = true;

  # Exclude default packages managed better via Nix or replaced by preferred alternatives
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover # Nix manages software declaratively; graphical app store is redundant
    konsole  # Preferred terminal emulator configured separately
  ];

  # SDDM Display Manager
  services.displayManager.sddm = {
    enable = true;
    theme = "catppuccin-mocha-mauve";
    extraPackages = with pkgs; [
      kdePackages.qt5compat
      kdePackages.qtsvg
      kdePackages.qtmultimedia # Required for animated/video backgrounds and sound
    ];
  };

  # KDE Connect phone integration daemon
  programs.kdeconnect.enable = true;

  # XDG Desktop Portals for Wayland screen sharing, file pickers, and sandbox integration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  # ============================================================================
  # 10. USER ACCOUNTS & SHELL CONFIGURATION
  # ============================================================================
  # Enable Zsh system-wide (shell binaries, completion scripts, and environment hooks)
  programs.zsh.enable = true;

  # Primary user definition
  users.users.fumoctl = {
    isNormalUser = true;
    shell = pkgs.zsh;

    # Allow user systemd services and timers to run without an active interactive login
    linger = true;

    # Automatically allocate sub-UID/GID ranges for rootless containerization (Podman/Docker)
    autoSubUidGidRange = true;

    # Supplemental user groups
    extraGroups = [
      "networkmanager" # Network configuration without root
      "wheel"          # Sudo / administrative privileges
      "libvirtd"       # Access to KVM/QEMU virtual machines
      "adm"            # System log inspection
      "docker"         # Docker daemon access
      "podman"         # Podman container management
    ];

    packages = with pkgs; [
      # Per-user packages can be declared here or via Home Manager
    ];
  };

  # ============================================================================
  # 11. DEVELOPMENT ENVIRONMENT & BINARY COMPATIBILITY
  # ============================================================================
  # Direnv: Automatic per-directory shell environments with Nix flake caching
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # GPG Agent with SSH key emulation and graphical pinentry
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  # nix-ld: Run unpatched, dynamically linked standard Linux binaries on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Additional shared libraries for unpatched binaries can be appended here
    ];
  };

  # ============================================================================
  # 12. WEB BROWSER ENTERPRISE POLICIES (FIREFOX HARDENING)
  # ============================================================================
  programs.firefox = {
    enable = true;

    policies = {
      # 1. Telemetry, Studies & Data Collection (Total Privacy Lockdown)
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableTelemetryServer = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false; # Set to true if you do not use Firefox Sync

      # 2. Search Engine Configuration
      SearchEngines = {
        Default = "Brave Search";
        PreventInstalls = false;
        Add = [
          {
            Name = "Brave Search";
            URLTemplate = "https://search.brave.com/search?q={searchTerms}";
            Alias = "@brave";
            Description = "Privacy-respecting search engine by Brave";
          }
        ];
        Remove = [
          "Google"
          "Bing"
          "Amazon.com"
          "eBay"
        ]; # Strip tracking-heavy defaults
      };

      # 3. Streamlined Declarative Extension Installs
      ExtensionSettings = {
        # uBlock Origin (Content blocker)
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Firefox Multi-Account Containers (Identity isolation)
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };
        # Cookie AutoDelete (Automatic tab/session cookie disposal)
        "CookieAutoDelete@kennydo.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi";
        };
      };

      # 4. Built-in Tracking Protection & Clean UI
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      FirefoxHome = {
        Pocket = false;
        Snippets = false;
        SponsoredTopSites = false;
        SponsoredStories = false;
        Highlights = false;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
        WhatsNew = false;
        FeatureRecommendations = false;
      };

      # Standardize locale context to English (US) to reduce browser fingerprint entropy
      RequestedLocales = [ "en-US" ];

      # 5. Core Privacy Preferences overrides (about:config level via policy)
      Preferences = {
        "privacy.privacyandsecurity.fingerprinting.protection" = true;
        "privacy.query_stripping.enabled" = true; # Strips tracking tokens (fbclid, utm_) from URLs
        "media.peerconnection.enabled" = false;    # Prevents WebRTC from leaking local/VPN IP addresses
        "network.dns.disablePrefetch" = true;      # Disables preemptive speculative DNS lookups
        "network.prefetch-next" = false;           # Prevents pre-fetching link destinations
        "browser.ml.chat.enabled" = false;         # Disables built-in telemetry-based AI integrations
        "browser.ml.linkPreview.enabled" = false;
        "dom.security.https_only_mode" = true;     # Enforces HTTPS everywhere
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };

  # ============================================================================
  # 13. GAMING & PERFORMANCE ACCELERATION
  # ============================================================================
  # Feral Interactive GameMode daemon: dynamic CPU governor and process niceness optimization
  programs.gamemode.enable = true;

  # Gamescope micro-compositor wrapper for resolution upscaling, integer scaling, and HDR
  programs.gamescope.enable = true;

  # Steam client and compatibility ecosystem
  programs.steam = {
    enable = true;
    extest.enable = true;               # Emulate X11 uinput events for controller mapping
    remotePlay.openFirewall = true;     # Steam Remote Play streaming ports
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;     # Dedicated Steam Big Picture Gamescope Wayland session

    # Custom Proton runner distributions
    extraCompatPackages = with pkgs; [
      proton-cachyos_x86_64_v3 # CachyOS Zen/x86-64-v3 optimized Proton build
      proton-ge-custom         # GloriousEggroll bleeding-edge Proton runner
    ];
  };

  # Udev rules for gaming controllers, VR headsets (Steam Controller, Valve Index, DualSense, etc.)
  hardware.steam-hardware.enable = true;

  # ============================================================================
  # 14. VIRTUALIZATION & CONTAINERS
  # ============================================================================
  # QEMU / KVM hypervisor daemon
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # Software TPM 2.0 emulator (required for Windows 11 VMs)
      vhostUserPackages = with pkgs; [
        virtiofsd # Fast host-to-guest shared folder filesystem driver (virtio-fs)
      ];
    };
  };

  # Virt-Manager graphical management interface for KVM/QEMU
  programs.virt-manager.enable = true;

  # SPICE agent daemon: automatic screen resizing and bidirectional clipboard sharing for VMs
  services.spice-vdagentd.enable = true;

  # Declarative Flatpak package support
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true; # Keep Flatpak environment purely declarative
  };

  # ============================================================================
  # 15. SYSTEM PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # --- Nix & Development Tooling ---
    nixd                      # Nix language server protocol (LSP)
    nixpkgs-fmt               # Nixpkgs code formatter
    nixfmt                    # Official Nix syntax formatter
    neovim                    # Extensible terminal text editor
    git                       # Distributed version control system
    meld                      # Graphical visual diff and merge tool

    # --- System Diagnostics, Hardware & File Utilities ---
    fastfetch                 # High-performance system information fetch tool
    file                      # Determine file types by magic numbers
    jq                        # Command-line JSON processor
    pciutils                  # PCI bus inspection utilities (lspci)
    ethtool                   # Query and control network driver and hardware settings
    sbctl                     # Secure Boot key manager
    _7zz                      # 7-Zip archiver (modern 7zz release)
    unrar                     # RAR archive extraction utility
    sshfs                     # Filesystem integration for KDE Connect

    # --- Desktop Environment, Theming & SDDM ---
    catppuccin-sddm           # Catppuccin theme assets for SDDM
    papirus-icon-theme        # Papirus icon theme for desktop and applications
    kdePackages.kamoso        # Webcam capture tool for KDE

    # --- Hardware, GPU & Gaming Performance ---
    lact                      # Linux AMD/Intel/Nvidia GPU configuration & overclocking GUI
    mangohud                  # Vulkan/OpenGL overlay for monitoring FPS, temps, and loads
    goverlay                  # Graphical frontend for configuring MangoHud and vkBasalt
    unstable.lsfg-vk-ui       # GUI manager for Lossless Scaling Frame Generation (lsfg-vk)
    mesa-demos                # Mesa OpenGL and Vulkan diagnostic utilities (glxinfo, vkcube)

    # --- Internet, Communication & Productivity ---
    unstable.equibop          # Discord client
    thunderbird               # Email, news, and calendar client
    unstable.onlyoffice-desktopeditors # Comprehensive office suite

    # --- Media Playback ---
    mpv                       # Highly configurable terminal and graphical media player

    # --- Container & Compatibility Layers ---
    distrobox                 # Containerized mutable Linux environments within NixOS
    appimage-run              # Wrapper to execute AppImage binaries on NixOS

    # --- Networking & Tunneling ---
    wget                      # Command-line network file downloader
    dnsmasq                   # Lightweight local DNS/DHCP server
    sshuttle                  # Transparent proxy server over SSH connection
    waypipe                   # Network proxy for Wayland applications

    # --- Specialized & Custom Packages ---
    google-antigravity        # Antigravity 2.0
    google-antigravity-cli    # Antigravity command line interface (agy)
    google-chrome             # Proprietary Chromium browser (Paired with antigravity)
    unstable.renpy            # Ren'Py visual novel engine
    unstable.cowsay           # Terminal speech bubble mascot
    unstable.lolcat           # Rainbow text colorizer
    unstable.haskellPackages.misfortune # Humorous fortune replacement
  ];

  # ============================================================================
  # 16. SYSTEM DOCUMENTATION
  # ============================================================================
  # Generate index cache for manual pages to speed up 'apropos' and 'man -k'
  documentation.man.cache.enable = true;
}
