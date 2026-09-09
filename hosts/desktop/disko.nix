{
  # ============================================================================
  # DECLARATIVE DISK PARTITIONING & FILESYSTEM CONFIGURATION (DISKO)
  # ============================================================================
  # Target Drive: High-speed NVMe SSD referenced by persistent hardware ID to
  # avoid device node renumbering (/dev/nvmeXn1) across kernel boots or drive changes.
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-UPULTR7K-4TSD_UPULTR7K4T25090017";
        content = {
          type = "gpt";
          partitions = {
            # ------------------------------------------------------------------
            # 1. EFI System Partition (ESP)
            # ------------------------------------------------------------------
            ESP = {
              size = "1G";
              type = "EF00"; # Standard UEFI system partition type code
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # umask=0077 restricts read/write permissions to root only, protecting
                # kernel images, initrd secrets, and Secure Boot signatures
                mountOptions = [ "umask=0077" ];
              };
            };

            # ------------------------------------------------------------------
            # 2. LUKS2 Encrypted Container
            # ------------------------------------------------------------------
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [ ];
                content = {
                  # ------------------------------------------------------------
                  # 3. Btrfs Filesystem with Subvolume Layout
                  # ------------------------------------------------------------
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    # Root subvolume: Base operating system state
                    "@" = {
                      mountpoint = "/";
                      # zstd provides transparent, high-throughput on-the-fly compression;
                      # noatime eliminates write overhead on read access
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    # User data: Kept separate for snapshot isolation and independent rollbacks
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    # Nix store: Isolated so builds and garbage collection don't pollute root snapshots
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    # System logs: Kept independent to preserve logs across system rollbacks
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    # Snapshot directory for local Btrfs snapshot managers (e.g. Snapper, btrbk)
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };

                    # Swap volume: Dedicated subvolume hosting an 8GB swapfile (CoW automatically disabled)
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "8G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
