{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    nix-flatpak.homeManagerModules.nix-flatpak
  ];

  home.username = "fumoctl";
  home.homeDirectory = "/home/fumoctl";
  home.stateVersion = "25.11";

  home.file.".ssh/config_source" = {
    text = ''
      Host github.com
          HostName github.com
          User git
          IdentityFile ~/.ssh/fumossh.key

      Host *
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes

    '';
    onChange = ''
      cp ~/.ssh/config_source ~/.ssh/config
      chmod 600 ~/.ssh/config
    '';
  };


  programs.git = {
    enable = true;
    signing = {
      key = "35FAC098F119E8FA";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "JuanU";
        email = "juanu@fumoctl.com";
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "dpoggi";
      plugins = [ "git" "sudo" ];
    };
  };
  programs.chromium = {
    enable = true;
    package = pkgs.unstable.brave; # Critical: Points the Chromium module to the Brave binary
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # Decentraleyes
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger

    ];
  };

  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "com.obsproject.Studio"
      "website.i2pd.i2pd"
      "com.usebottles.bottles"
      "com.vysp3r.ProtonPlus"
      "com.github.Matoking.protontricks"
      "com.discordapp.Discord"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    overrides.settings."com.usebottles.bottles".Context.filesystems = [ "home" ];
  };
  home.activation = {
    configureFlatpakLanguages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';
  };
}
