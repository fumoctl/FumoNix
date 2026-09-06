{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  home.username = "fumoctl";
  home.homeDirectory = "/home/fumoctl";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    unstable.ptyxis
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
      plugins = [
        "git"
        "sudo"
      ];
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };

  xdg.desktopEntries."org.gnome.Ptyxis" = {
    name = "Ptyxis";
    genericName = "Terminal";
    comment = "A terminal for GNOME";
    # %U passes the directory URI from Dolphin/KDE
    exec = "ptyxis --new-window %U";
    icon = "org.gnome.Ptyxis";
    terminal = false;
    categories = [ "System" "TerminalEmulator" ];
    startupNotify = true;
  };

  # 3. Disable session restore
  dconf.settings = {
    "org/gnome/Ptyxis" = {
      restore-session = false;
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
  home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/org.kde.plasma.browser_integration.json" =
    {
      source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };

  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "com.obsproject.Studio"
      "com.usebottles.bottles"
      "com.vysp3r.ProtonPlus"
      "com.github.Matoking.protontricks"
      "com.ranfdev.DistroShelf"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    uninstallUnmanaged = false;
  };
  home.activation = {
    configureFlatpakLanguages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';
    fixobsqt = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user --unset-env=QT_PLUGIN_PATH --unset-env=LD_LIBRARY_PATH --unset-env=QT_QPA_PLATFORM_PLUGIN_PATH com.obsproject.Studio
    '';
    overrideBottlesFsHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user --filesystem=home com.usebottles.bottles
    '';
  };

  programs.plasma = {
    enable = true;
    workspace = {
      theme = "default";
      colorScheme = "BreezeDark";
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "breeze-dark";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
    };
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

    spectacle.shortcuts = {
      captureEntireDesktop = "Meta+Print";
      captureRectangularRegion = "Meta+Shift+Print";
      captureActiveWindow = "Meta+Ctrl+Print";
      launch = "";
    };

    configFile = {
      "kcminputrc"."Mouse" = {
        pointerAccelerationProfile = 1;
        pointerAcceleration = 0.0;
      };
      "kcminputrc"."Libinput"."pointerAccelerationProfile" = 1;
      "kdeglobals"."General" = {
        TerminalApplication = "ptyxis";
        TerminalService = "org.gnome.Ptyxis.desktop";
        BrowserApplication = "brave-browser.desktop";
      };
      "kdeglobals"."KDE Connect" = {
        # Phone handler
        tel = "org.kde.kdeconnect.handler.desktop";
      };
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
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web & Email
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "x-scheme-handler/tel" = "org.kde.kdeconnect.handler.desktop";

      # Multimedia
      "image/png" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "audio/mpeg" = "org.kde.elisa.desktop";
      "audio/flac" = "org.kde.elisa.desktop";
      "audio/x-vorbis+ogg" = "org.kde.elisa.desktop";
      "video/mp4" = "umpv.desktop";
      "video/mkv" = "umpv.desktop";
      "video/webm" = "umpv.desktop";
      "video/x-matroska" = "umpv.desktop";

      # Documents
      "text/plain" = "code.desktop";
      "application/pdf" = "org.kde.okular.desktop";

      # Utilities
      "inode/directory" = "org.kde.dolphin.desktop";
      "application/zip" = "org.kde.ark.desktop";
      "application/x-tar" = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/vnd.rar" = "org.kde.ark.desktop";

      # Map handler (Geo scheme)
      "x-scheme-handler/geo" = "google-maps-geo-handler.desktop";
    };
  };
}
