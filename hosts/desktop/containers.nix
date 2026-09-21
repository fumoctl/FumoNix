{ config
, lib
, pkgs
, ...
}:

{
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    podman = {
      enable = true;
    
      # CRITICAL: Do NOT enable dockerCompat or dockerSocket.enable
      dockerCompat = false;             # Leaves the `docker` CLI pointing to dockerd
      dockerSocket.enable = false;      # Leaves /var/run/docker.sock to Docker

      # Enable Netavark/DNS support for Podman internal container resolution
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # --- Container Orchestration & CLI ---
    docker-compose      # Official Compose v2 plugin/binary for rootful Docker
    podman-compose      # Compose parser for Podman
    podman-desktop

    # --- Local Kubernetes & Workloads ---
    kind                # Kubernetes IN Docker/Podman
    kubectl             # K8s CLI
    helm                # K8s package manager
    k9s                 # Fast terminal UI for interacting with your K8s clusters

    # --- Image Inspection & Registries ---
    skopeo              # Inspect, copy, and sign container images without pulling/running them
    dive                # Inspect layer-by-layer contents and sizes of container images

    # --- Rootless / CNI Utilities ---
    shadow              # Provides subuid/subgid helpers (newuidmap, newgidmap)
    fuse-overlayfs      # Fallback userspace storage driver for unprivileged containers
  ];

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      almalinux = {
        image = "docker.io/library/almalinux:latest";
        autoStart = true;
        cmd = [ "sleep" "infinity" ];
        podman.user = "fumoctl";
        volumes = [          
          "almalinux-data:/data:Z"
          # or Format: "/host/path:/container/path:Z"
        ];
      };
    };
  };
}
