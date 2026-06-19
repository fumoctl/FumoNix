{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
    inputs.antigravity-nix.overlays.default
  ];

  boot.loader.limine.enable = true;
  boot.loader.limine.secureBoot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.unstable.linuxPackages_xanmod_latest;
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
    hostName = "nixos";
    resolvconf.useLocalResolver = true;
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager = {
      enable = true;
      dns = "none";
      settings = {
        main = {
          dns = "none";
        };
        connection = {
          "ipv4.ignore-auto-dns" = true;
          "ipv6.ignore-auto-dns" = true;
        };
      };
    };
    firewall = {
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
      allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
    };
  };
  services.resolved.enable = false;
  services.stubby = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1" "0::1" ];
      resolution_type = "GETDNS_RESOLUTION_STUB";
      dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
      tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
      upstream_recursive_servers = [
        {
          address_data = "94.140.14.14";
          tls_auth_name = "dns.adguard-dns.com";
        }
        {
          address_data = "94.140.15.15";
          tls_auth_name = "dns.adguard-dns.com";
        }
        {
          address_data = "2a10:50c0::ad1:ff";
          tls_auth_name = "dns.adguard-dns.com";
        }
        {
          address_data = "2a10:50c0::ad2:ff";
          tls_auth_name = "dns.adguard-dns.com";
        }
      ];
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

  ## NVIDIA
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.nvidia = {
  #  modesetting.enable = true;
  #  open = true;
  #  powerManagement.enable = true;
  #  powerManagement.finegrained = true;
  #  nvidiaSettings = true;
  #  #Comment these when not using dual gpus on laptops
  #  prime = {
  #    offload.enable = true;
  #    offload.enableOffloadCmd = true; # This creates the `nvidia-offload` script
  #    # Replace these with the corresponding value from the lspci command ```nix-shell -p pciutils --run "lspci"```
  #    #intelBusId = "PCI:0:2:0"; 
  #    amdgpuBusId = "PCI:66:0:0";
  #    nvidiaBusId = "PCI:64:0:0";
  #  };
  #};


  #Power Management
  services.power-profiles-daemon.enable = false;
  hardware.system76.enableAll = true;

  ## TUXEDO Drivers
  #hardware.tuxedo-drivers.enable = true;
  #hardware.tuxedo-rs = {
  #  enable = true;
  #  tailor-gui.enable = true;
  #};   

  # GPU Daemon (Overclocking/Fan control)
  services.lact.enable = true;

  time.timeZone = "America/Asuncion";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
  };

  services.desktopManager.cosmic.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-player
    cosmic-reader
    cosmic-store
  ];
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "cosmic";
    COSMIC_DATA_CONTROL_ENABLED = "1";
  };
  services.displayManager.cosmic-greeter.enable = true;
  programs.kdeconnect.enable = true;

  users.users.fumoctl = {
    isNormalUser = true;
    autoSubUidGidRange = true;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "adm" ];
    packages = with pkgs; [

    ];
  };

  environment.systemPackages = with pkgs; [
    nixd
    nixpkgs-fmt
    cutecosmic
    neovim
    unstable.ptyxis
    resources
    wget
    git
    file
    sbctl
    dnsmasq
    waypipe
    unstable.vscodium-fhs
    google-antigravity
    google-antigravity-ide
    google-antigravity-cli
    unstable.winboat
    unstable.onlyoffice-desktopeditors
    meld
    distrobox
    _7zz
    unrar
    fastfetch
    thunderbird
    mpv
    gthumb
    lollypop
    appimage-run
    mangohud
    goverlay
    lact
    unstable.lsfg-vk-ui
    (pkgs.unstable.heroic.override {
      extraPkgs = p: [
        pkgs.unstable.gamescope
        pkgs.unstable.gamemode
      ];
    })
    ethtool
    pciutils
    mesa-demos
    unstable.renpy
    unstable.haskellPackages.misfortune
    unstable.cowsay
    unstable.lolcat
    unstable.proton-vpn-cli
    sshuttle
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

  programs.firefox.enable = true;

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  services.flatpak={
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
    docker.enable = false; # Disable Docker if using Podman
    podman = {
      enable = true;
      dockerCompat = true; # Aliases docker -> podman
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = [ pkgs.podman-compose ];
    };
  };

  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true; # Clipboard sharing with VMs

  documentation.man.cache.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";

}
