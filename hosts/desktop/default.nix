{
  config,
  lib,
  pkgs,
  ...
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
    secureBoot.enable = true;
  };

  boot.kernelPackages = pkgs.unstable.linuxPackages_xanmod_latest;

  boot.kernelParams = [
    "amdgpu.runpm=0"
  ];

  system.stateVersion = "26.05";
}
