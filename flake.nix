{
  description = "Fumoctl's ultimate NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nyarch-nix = {
      url = "github:fumoctl/Nyarch-Nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nyx-cache.chaotic.cx"
    ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , nix-flatpak
    , plasma-manager
    , disko
    , chaotic
    , ...
    }@inputs:
    {
      nixosConfigurations = {
        fumonix-laptop = nixpkgs.lib.nixosSystem {
          # This makes 'inputs' available to configuration.nix and home.nix
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./hosts/laptop/default.nix
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            chaotic.nixosModules.nyx-cache
            chaotic.nixosModules.nyx-overlay
            chaotic.nixosModules.nyx-registry
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.fumoctl = import ./hosts/common/home.nix;
                extraSpecialArgs = { inherit inputs; }; # Also pass to Home Manager
                backupFileExtension = "backup";
              };
            }
          ];
        };

        fumonix-desktop = nixpkgs.lib.nixosSystem {
          # This makes 'inputs' available to configuration.nix and home.nix
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./hosts/desktop/default.nix
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            chaotic.nixosModules.nyx-cache
            chaotic.nixosModules.nyx-overlay
            chaotic.nixosModules.nyx-registry
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.fumoctl = import ./hosts/common/home.nix;
                extraSpecialArgs = { inherit inputs; }; # Also pass to Home Manager
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };
    };
}
