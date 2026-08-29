{ config, lib, pkgs, ... }:

# Tuxedo InfinityBook Max 15 - Gen10 - AMD

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "fumonix-laptop";

  boot.loader.limine = {
    secureBoot.enable = false;
  };

  boot.kernelPackages = pkgs.unstable.linuxPackages;

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
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

  # Motorcomm YT6801 Gigabit Ethernet driver
  boot.extraModulePackages = [
    config.boot.kernelPackages.yt6801
  ];
  
  boot.kernelModules = [ "yt6801" ];

  programs.captive-browser = {
    enable = true;
    interface = "wlp98s0"; # Replace with your network interface
    # Optional: customize browser or socks5-addr
  };

  system.stateVersion = "26.05";
}
