{
  description = "Fumoctl's NixOS configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    hyprland.url = "github:hyprwm/Hyprland/v0.55.0";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";  # Use same quickshell version
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nix-flatpak, hyprland, ... }@inputs: {
    nixosConfigurations.fumonix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # This makes 'inputs' available to configuration.nix and home.nix
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.fumoctl = import ./home.nix;
            extraSpecialArgs = { inherit inputs; }; # Also pass to Home Manager
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
