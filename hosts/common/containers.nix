{ config, lib, pkgs, ... }:

{
  virtualisation = {
    docker.enable = false; # Disable Docker if using Podman
    podman = {
      enable = true;
      dockerCompat = true; # Aliases docker -> podman
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  environment.systemPackages = with pkgs; [
      podman-tui
      podman-desktop
      podman-compose
      helm
      kubectl
      kind
  ];

  # Enable Podman backend
  virtualisation.oci-containers.backend = "podman";

  # Define your containers
  #virtualisation.oci-containers.containers = {
  #  
  #};
}