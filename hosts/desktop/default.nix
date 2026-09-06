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

  networking.hostName = "fumonix-desktop";

  boot.loader.limine = {
    secureBoot.enable = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

  boot.kernelParams = [
    "amdgpu.runpm=0"
  ];

  system.stateVersion = "26.05";
}
