{ config
, lib
, pkgs
, ...
}:

{
  imports = [
    ../common/default.nix

    ./hardware-configuration.nix

    ./disko.nix

    ./containers.nix
  ];

  networking.hostName = "fumonix-laptop";

  programs.captive-browser = {
    enable = true;
    interface = "wlp98s0";
  };

  boot.loader.limine = {
    secureBoot.enable = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4.extend (final: prev: {
    tuxedo-drivers = prev.tuxedo-drivers.override { pahole = pkgs.pahole; };
  });

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    open = true;

    package = pkgs.nvidia_cachyos-lto;

    powerManagement.enable = true;
    powerManagement.finegrained = false;

    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:66:0:0";
      nvidiaBusId = "PCI:64:0:0";
    };
  };

  hardware.tuxedo-drivers.enable = true;

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  system.stateVersion = "26.05";
}
