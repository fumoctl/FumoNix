{ config
, lib
, pkgs
, inputs
, ...
}:

{
  imports = [
    ./stylix.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
    inputs.antigravity-nix.overlays.default
    inputs.nyarch-nix.overlays.default
  ];

  boot.loader.limine = {
    enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelModules = [ "ntsync" ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # SteamOS default
  };

  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576";
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-"; # "-" sets both soft and hard limits
      item = "nofile";
      value = "1048576";
    }
  ];

  networking = {
    nftables.enable = true;

    # Hand off local resolution directly to systemd-resolved
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      settings = {
        main = {
          dns = "systemd-resolved";
        };
        connection = {
          "ipv4.ignore-auto-dns" = true;
          "ipv6.ignore-auto-dns" = true;
          "wifi.cloned-mac-address" = "stable-temporary";
          "ethernet.cloned-mac-address" = "stable-temporary";
          "ipv6.ip6-privacy" = 2;
        };
        device = {
          "wifi.scan-rand-mac-address" = "yes";
        };
      };
    };

    firewall = {
      enable = true;
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
  # Disable unbound
  services.unbound.enable = false;
  # Enable systemd-resolved with AdGuard DNS-over-TLS
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
        Domains = [ "~." ];
      };
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  systemd.package = pkgs.systemd.override { withUserDb = false; };
  services.userdbd.enable = lib.mkForce false;

  security.rtkit.enable = true; # Realtime priority for audio

  services.pulseaudio.enable = false; # Disable PulseAudio in favor of PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.xserver = {
    enable = true; # Required for X11 layout configuration
    xkb.layout = "us";
    xkb.variant = "altgr-intl";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam/Wine
    extraPackages = [
      pkgs.unstable.lsfg-vk
    ];
  };

  # Power Management
  services.power-profiles-daemon.enable = true;
  hardware.system76.enableAll = false;

  # GPU Daemon (Overclocking/Fan control)
  services.lact.enable = true;

  # Mouse
  services.libinput = {
    enable = true;

    mouse = {
      # "flat" disables acceleration (1:1 movement)
      accelProfile = "flat";
      # Optional: Adjust sensitivity if needed (-1.0 to 1.0), 0 is default
      # accelSpeed = "0";
    };
  };

  services.automatic-timezoned.enable = true;
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    konsole
  ];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  programs.kdeconnect.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  users.users.fumoctl = {
    isNormalUser = true;
    autoSubUidGidRange = true;
    linger = true;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "adm"
      "docker"
      "podman"
      "OCI"
    ];
    packages = with pkgs; [

    ];
  };

  environment.systemPackages = with pkgs; [
    nixd
    nixpkgs-fmt
    nixfmt
    neovim
    kdePackages.plasma-browser-integration
    kdePackages.kamoso
    wget
    git
    file
    sbctl
    dnsmasq
    waypipe
    unstable.onlyoffice-desktopeditors
    meld
    distrobox
    _7zz
    unrar
    fastfetch
    thunderbird
    mpv
    appimage-run
    mangohud
    goverlay
    lact
    unstable.lsfg-vk-ui
    jq
    ethtool
    pciutils
    mesa-demos
    unstable.renpy
    unstable.haskellPackages.misfortune
    unstable.cowsay
    unstable.lolcat
    unstable.equibop
    sshuttle
    google-antigravity
    google-antigravity-cli
    google-chrome
    nyarchassistant
    catgirldownloader
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  programs.zsh = {
    enable = true;
  };

  programs.firefox = {
    enable = true;

    # System-wide enterprise policies
    policies = {
      # 1. Telemetry, Studies & Data Collection (Total Lockdown)
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableTelemetryServer = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false; # Set to true if you do not use Firefox Sync

      # 2. Set Default Search Engine to Brave Search
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
        ]; # Clean out tracking-heavy defaults
      };

      # 3. Streamlined Extensions Setup (uBlock Origin + LocalCDN)
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Firefox Multi-Account Containers
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };
        # Cookie AutoDelete
        "CookieAutoDelete@kennydo.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi";
        };
      };

      # 4. Built-in Tracking Protection & UI Cleanup
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

      # Forces the browser language context to English to make your fingerprint less unique
      RequestedLocales = [ "en-US" ];

      # 5. Core Privacy Preferences overrides (about:config level via policy)
      Preferences = {
        "privacy.privacyandsecurity.fingerprinting.protection" = true;
        "privacy.query_stripping.enabled" = true; # Strips tracking tokens (like fbclid, utm_) from URLs
        "media.peerconnection.enabled" = false; # Prevents WebRTC from leaking your real IP behind a VPN
        "network.dns.disablePrefetch" = true; # Stops DNS lookups to links before you click them
        "network.prefetch-next" = false;
        "browser.ml.chat.enabled" = false; # Turns off default local AI integrations/network calls
        "browser.ml.linkPreview.enabled" = false;
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-cachyos_x86_64_v3
      proton-ge-custom
    ];
  };
  hardware.steam-hardware.enable = true;

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
  };

  # Dynamically linked executables
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [

  ];

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      ipafont
      kochi-substitute
      liberation_ttf
      nerd-fonts.symbols-only
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu
      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono

    ];
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true; # TPM support for Windows 11 VMs
        vhostUserPackages = with pkgs; [ virtiofsd ];
      };
    };
  };

  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true; # Clipboard sharing with VMs

  documentation.man.cache.enable = true;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" "@wheel" ];
  };
  nixpkgs.config.allowUnfree = true;
}
