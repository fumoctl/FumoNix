{ config, lib, pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./containers.nix
  ];

  boot.loader.limine = {
    secureBoot.enable = true;
  };

  boot.kernelPackages = pkgs.unstable.linuxPackages_xanmod_latest;
  
  boot.kernelParams = [
    "amdgpu.runpm=0"
  ];
  
  networking.hostName = "fumonix-desktop";

  system.stateVersion = "26.05";
}
