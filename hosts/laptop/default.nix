{ config, lib, pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "fumonix-laptop";

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
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

  system.stateVersion = "26.05";
}
