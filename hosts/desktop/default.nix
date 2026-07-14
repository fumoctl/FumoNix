{ config, lib, pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
  ];
  
  boot.kernelParams = [
    "amdgpu.runpm=0"
  ];
  
  networking.hostName = "fumonix-desktop";

  system.stateVersion = "26.05";
}
