# TEMPLATE: Replace this file with the generated 'hardware-configuration.nix'
# from your desktop system (usually found under /etc/nixos/hardware-configuration.nix)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/luks-6ce861aa-57f9-4cde-98ac-c3bda9deb4c7";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-6ce861aa-57f9-4cde-98ac-c3bda9deb4c7".device = "/dev/disk/by-uuid/6ce861aa-57f9-4cde-98ac-c3bda9deb4c7";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D5A5-D7D8";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/2976a251-edbd-4aa4-8cfa-60cdf950b09b"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
