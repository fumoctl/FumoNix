{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })

    inputs.github-copilot-nix.overlays.default
    inputs.antigravity-nix.overlays.default
  ];

  boot = {
    loader = {
      limine.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelModules = [ "ntsync" "tun" "wireguard" ];

    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
  };

  systemd.settings.Manager.DefaultLimitNOFILE = "1048576";
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576";

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "1048576";
    }
  ];

  systemd.package = pkgs.systemd.override { withUserDb = false; };
  services.userdbd.enable = lib.mkForce false;

  networking = {
    nftables.enable = true;

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
      checkReversePath = "loose";
      trustedInterfaces = [ "tun0" "tun2" "amn0" ];
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

  services.unbound.enable = false;

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "true";
        DNSOverTLS = "true";
        DNS = [
          "94.140.14.14#dns.adguard-dns.com"
          "94.140.15.15#dns.adguard-dns.com"
          "2a10:50c0::ad1:ff#dns.adguard-dns.com"
          "2a10:50c0::ad2:ff#dns.adguard-dns.com"
        ];
        FallbackDNS = [
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
          "2620:fe::fe#dns.quad9.net"
          "2620:fe::9#dns.quad9.net"

          "194.242.2.4#base.dns.mullvad.net"
          "2a07:e340::4#base.dns.mullvad.net"
        ];
        Domains = [ "~." ];
      };
    };
  };

  programs.amnezia-vpn = {
    enable = true;
    package = pkgs.unstable.amnezia-vpn;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.unstable.lsfg-vk
    ];
  };

  services.lact.enable = true;

  services.power-profiles-daemon.enable = true;
  hardware.system76.enableAll = false;

  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
    };
  };

  security.rtkit.enable = true;

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.automatic-timezoned.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      ipafont
      kochi-substitute

      noto-fonts-color-emoji

      liberation_ttf

      nerd-fonts.symbols-only
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu
      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];

    fontconfig.defaultFonts = {
      monospace = [
        "JetBrainsMono Nerd Font"
        "Noto Sans Mono CJK JP"
      ];
      sansSerif = [
        "Noto Sans CJK JP"
        "Liberation Sans"
      ];
      serif = [
        "Noto Serif CJK JP"
        "Liberation Serif"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    konsole
  ];

  services.displayManager.sddm = {
    enable = true;
    theme = "catppuccin-mocha-blue";
    extraPackages = with pkgs; [
      kdePackages.qt5compat
      kdePackages.qtsvg
      kdePackages.qtmultimedia
    ];
  };

  programs.kdeconnect.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  programs.zsh.enable = true;

  users.users.fumoctl = {
    isNormalUser = true;
    shell = pkgs.zsh;

    linger = true;

    autoSubUidGidRange = true;

    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "adm"
      "docker"
      "podman"
    ];

    packages = with pkgs; [
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-all;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
    ];
  };

  programs.gamemode.enable = true;

  programs.gamescope.enable = true;

  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;

    extraCompatPackages = with pkgs; [
      proton-cachyos
      proton-ge-custom
    ];
  };

  hardware.steam-hardware.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [
        virtiofsd
      ];
    };
  };

  programs.virt-manager.enable = true;

  services.spice-vdagentd.enable = true;

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
  };

  environment.systemPackages = with pkgs; [
    nixd
    nixpkgs-fmt
    nixfmt
    neovim
    git
    meld

    fastfetch
    file
    jq
    pciutils
    ethtool
    sbctl
    _7zz
    unrar
    sshfs

    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "blue";
    })
    (catppuccin-kde.override {
      flavour = [ "mocha" ];
      accents = [ "blue" ];
    })
    bibata-cursors
    kdePackages.kamoso

    lact
    mangohud
    goverlay
    unstable.lsfg-vk-ui
    mesa-demos

    unstable.equibop
    thunderbird
    unstable.onlyoffice-desktopeditors
    unstable.mullvad-browser

    mpv

    distrobox
    appimage-run

    wget
    dnsmasq
    sshuttle
    waypipe
    iptables
    iproute2
    wireguard-tools
    openresolv

    unstable.renpy
    unstable.cowsay
    unstable.lolcat
    unstable.haskellPackages.misfortune
    github-copilot-desktop
    github-copilot-cli
    google-antigravity
    google-antigravity-cli
    google-chrome
  ];

  documentation.man.cache.enable = true;
}
