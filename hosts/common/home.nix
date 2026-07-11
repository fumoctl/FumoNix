{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  home.username = "fumoctl";
  home.homeDirectory = "/home/fumoctl";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    
  ];

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
    dotDir = config.home.homeDirectory;
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
      { id = "cimiefiiaegbelhefglklhhakcgmhkai"; } # Plasma Integration
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # Decentraleyes
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger

    ];
  };
  home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/org.kde.plasma.browser_integration.json" = {
    source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
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
      "dev.vencord.Vesktop"
      "com.ranfdev.DistroShelf"
      "com.protonvpn.www"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    uninstallUnmanaged = false;
    overrides.settings."com.usebottles.bottles".Context.filesystems = [ "home" ];
  };
  home.activation = {
    configureFlatpakLanguages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';
  };

  programs.plasma = {
    enable = true;
    #workspace.lookAndFeel = "org.kde.breezedark.desktop";
    panels = [
      {
        location = "bottom";
        floating = true;
        height = 32;
        widgets = [
          {
            kickoff = {
              icon = "nix-snowflake-white";
              sortAlphabetically = true;
            };
          }
          "org.kde.plasma.icontasks"
          "org.kde.plasma.marginsseparator"
          {
            pager = { };
          }
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              time.format = "24h";
              calendar.firstDayOfWeek = "monday";
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];



    shortcuts = {

      kwin."Switch to Desktop 1" = "Meta+1";
      kwin."Switch to Desktop 2" = "Meta+2";
      kwin."Switch to Desktop 3" = "Meta+3";
      kwin."Switch to Desktop 4" = "Meta+4";
      kwin."Switch to Desktop 5" = "Meta+5";
      kwin."Switch to Desktop 6" = "Meta+6";
      kwin."Switch to Desktop 7" = "Meta+7";
      kwin."Switch to Desktop 8" = "Meta+8";
      kwin."Switch to Desktop 9" = "Meta+9";

      kwin."Window to Desktop 1" = "Meta+!";
      kwin."Window to Desktop 2" = "Meta+@";
      kwin."Window to Desktop 3" = "Meta+#";
      kwin."Window to Desktop 4" = "Meta+$";
      kwin."Window to Desktop 5" = "Meta+%";
      kwin."Window to Desktop 6" = "Meta+^";
      kwin."Window to Desktop 7" = "Meta+&";
      kwin."Window to Desktop 8" = "Meta+*";
      kwin."Window to Desktop 9" = "Meta+(";

      "services/brave-browser.desktop"._launch = "Meta+B";
      "services/org.kde.konsole.desktop"._launch = [ "Meta+Return" "Meta+T" ];


    };
    spectacle.shortcuts = {
      captureEntireDesktop = "Meta+Print";
      captureRectangularRegion = "Meta+Shift+Print";
      captureActiveWindow = "Meta+Ctrl+Print";
    };

    configFile = {
      kwinrc = {
        Desktops.Number = 4;
        Desktops.Rows = 1;
        "Windows" = {
          # Options: ClickToFocus (default), FocusFollowsMouse, FocusUnderMouse, FocusStrictlyUnderMouse
          "FocusPolicy" = "FocusFollowsMouse";
          
          # Optional: Delay in milliseconds before focusing (0 = instant)
          "DelayFocusInterval" = 0; 
        };
      };
    };
  };
}
