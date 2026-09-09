{ config
, lib
, pkgs
, ...
}:

{
  # ============================================================================
  # 1. CONTAINER VIRTUALIZATION ENGINE (PODMAN)
  # ============================================================================
  virtualisation = {
    # Explicitly disable standard Docker daemon to prevent conflicts with Podman
    docker.enable = false;

    podman = {
      enable = true;

      # Creates symlinks and wrapper scripts alias 'docker' -> 'podman'
      dockerCompat = true;

      # Enable Docker-compatible UNIX socket (/run/podman/podman.sock)
      # Essential for Docker Compose, VS Code Dev Containers, and container GUIs
      dockerSocket.enable = true;

      # Enable Netavark / Aardvark-dns internal DNS resolution between containers
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # ============================================================================
  # 2. CONTAINER & KUBERNETES MANAGEMENT PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # --- Container Orchestration & Tooling ---
    podman-compose      # Compose specification implementation for Podman
    podman-tui          # Interactive terminal UI for inspecting pods and containers
    podman-desktop      # Graphical desktop dashboard for containers and Kubernetes

    # --- Cloud Native & Kubernetes CLI ---
    kubectl             # Kubernetes command-line management tool
    helm                # Kubernetes package manager and chart deployment tool
  ];

  # ============================================================================
  # 3. DECLARATIVE OCI CONTAINERS
  # ============================================================================
  # Systemd-managed declarative containers using the Podman runtime engine
  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      # Sample declarative service running rootless under user 'fumoctl'
      my-service = {
        image = "docker.io/nginx:alpine";
        autoStart = true;
        podman.user = "fumoctl";
      };
    };
  };
}
