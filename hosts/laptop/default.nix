{ config, lib, pkgs, ... }:

# Tuxedo InfinityBook Max 15 - Gen10 - AMD

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./containers.nix
  ];

  networking.hostName = "fumonix-laptop";

  boot.loader.limine = {
    secureBoot.enable = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = pkgs.nvidia_cachyos-lto;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # This creates the `nvidia-offload` script
      amdgpuBusId = "PCI:66:0:0";
      nvidiaBusId = "PCI:64:0:0";
    };
  };

  # TUXEDO Drivers
  hardware.tuxedo-drivers.enable = true;
  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # Motorcomm YT6801 Gigabit Ethernet driver ## Not Needed on linux kernel > 7.0
  #boot.extraModulePackages = [
  #  (config.boot.kernelPackages.yt6801.overrideAttrs (old: {
  #    makeFlags = (old.makeFlags or [ ]) ++ config.boot.kernelPackages.kernelModuleMakeFlags;
  #  }))
  #];
  #boot.kernelModules = [ "yt6801" ];

  programs.captive-browser = {
    enable = true;
    interface = "wlp98s0"; # Replace with your network interface
    # Optional: customize browser or socks5-addr
  };

  system.stateVersion = "26.05";
}
