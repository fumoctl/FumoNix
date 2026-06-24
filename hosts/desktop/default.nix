{ config, lib, pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "fumonix-desktop";

  system.stateVersion = "26.05";
}
