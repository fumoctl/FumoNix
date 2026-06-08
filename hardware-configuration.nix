{ config, lib, pkgs, inputs, modulesPath, ... }:

let
  diskDevice = "/dev/nvme0n1";
in

{
  imports = [
    inputs.disko.nixosModules.disko
    (modulesPath + "/installer/scan/not-detected.nix")
    ];


  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [ "amdgpu.sg_display=0" ];
  boot.extraModulePackages = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  disko.devices = {
    disk.main = {
      type = "disk";
      device = diskDevice;
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@log" = {
                    mountpoint = "/log";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@snapshots" = {
                    mountpoint = "/snapshots";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
                  };

                  "@tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
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