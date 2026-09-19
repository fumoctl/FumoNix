{ config
, pkgs
, inputs
, lib
, ...
}:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak

    inputs.plasma-manager.homeModules.plasma-manager
  ];

  home = {
    username = "fumoctl";
    homeDirectory = "/home/fumoctl";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [
    unstable.ptyxis

    kdePackages.plasma-browser-integration

    bibata-cursors
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
    gitCredentialHelper.enable = true;
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

  xdg.desktopEntries."org.gnome.Ptyxis" = {
    name = "Ptyxis";
    genericName = "Terminal";
    comment = "A terminal for GNOME";
    exec = "ptyxis --new-window %U";
    icon = "org.gnome.Ptyxis";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    startupNotify = true;
  };

  dconf.settings = {
    "org/gnome/Ptyxis" = {
      restore-session = false;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;

    mutableExtensionsDir = true;
  };

  programs.brave = {
    enable = true;
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass (Password manager)
      { id = "cimiefiiaegbelhefglklhhakcgmhkai"; } # Plasma Integration (Media controls & downloads)
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # Decentraleyes (Local CDN emulation)
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger (Heuristic tracker blocker)
      { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
      { id = "gbkeegbaiigmenfmjfclcdgdpimamgkj"; } # Google Docs MS Office
      { id = "donbcfbmhbcapadipfkeojnmajbakjdc"; } # Ruffle - Flash Emulator

    ];
  };

  # Native messaging host bridge for Brave to communicate with KDE Plasma system tray & media keys
  xdg.configFile."BraveSoftware/Brave-Browser/NativeMessagingHosts/org.kde.plasma.browser_integration.json".source =
    "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

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

  home.file.".local/share/themes/catppuccin-mocha-blue-standard".source =
    "${pkgs.catppuccin-gtk.override { accents = [ "blue" ]; variant = "mocha"; }}/share/themes/catppuccin-mocha-blue-standard";

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
    flatpakThemeOverrides = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user \
        --filesystem=/nix/store:ro \
        --filesystem=xdg-data/themes:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=xdg-config/kdeglobals:ro \
        --env=GTK_THEME=catppuccin-mocha-blue-standard \
        --env=ICON_THEME=breeze-dark
    '';
  };

  gtk = {
    enable = true;
    gtk2.enable = false;
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 20;
      package = pkgs.bibata-cursors;
    };
    font = {
      name = "Noto Sans CJK JP";
      size = 10;
      package = pkgs.noto-fonts-cjk-sans;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true;

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";

      colorScheme = "CatppuccinMochaBlue";

      iconTheme = "breeze-dark";

      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 20;
      };

      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}";
    };

    fonts = {
      general = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      fixedWidth = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };

      small = {
        family = "Noto Sans CJK JP";
        pointSize = 8;
      };

      toolbar = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      menu = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      windowTitle = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };
    };

    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 1;
      };

      titlebarButtons = {
        left = [ "more-window-actions" ];
        right = [ "minimize" "maximize" "close" ];
      };

      effects = {
        blur.enable = true;
      };
    };

    kscreenlocker = {
      autoLock = true;
      timeout = 10;
      lockOnResume = true;
      passwordRequired = true;
      passwordRequiredDelay = 0;
      appearance.wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}";
    };

    session = {
      sessionRestore = {
        restoreOpenApplicationsOnLogin = "startWithEmptySession";
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
          {
          iconTasks = {
            launchers = [
              "applications:org.gnome.Ptyxis.desktop"
              "applications:org.kde.dolphin.desktop"
              "applications:brave-browser.desktop"
            ];
          };
          }
          "org.kde.plasma.marginsseparator"
          {
            pager = { };
          }
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              date = {
                enable = true;
                position = "belowTime";
                format.custom = "dd/MM/yyyy";
              };
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
      "kcminputrc"."Libinput" = {
        pointerAccelerationProfile = 1;
      };
      "kcminputrc"."Libinput/Defaults" = {
        pointerAccelerationProfile = 1;
      };

      "kcminputrc"."Libinput/13991/43128/WL WLMOUSE SWORD X 8K RECEIVER" = {
        PointerAccelerationProfile = 1;
      };
      "kcminputrc"."Libinput/13991/43129/WL WLMOUSE SWORD X" = {
        PointerAccelerationProfile = 1;
      };
      "kcminputrc"."Libinput/1133/16500/Logitech G305" = {
        PointerAccelerationProfile = 1;
      };

      "kdeglobals"."General" = {
        TerminalApplication = "ptyxis";
        TerminalService = "org.gnome.Ptyxis.desktop";
        BrowserApplication = "brave-browser.desktop";
      };
      "kdeglobals"."KDE Connect" = {
        tel = "org.kde.kdeconnect.handler.desktop";
      };

      "ksplashrc"."KSplash" = {
        Engine = "none";
        Theme = "None";
      };

      kwinrc = {
        Desktops.Number = 4;
        Desktops.Rows = 1;
        "Windows" = {
          "FocusPolicy" = "FocusFollowsMouse";
          "DelayFocusInterval" = 0;
        };
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "x-scheme-handler/tel" = "org.kde.kdeconnect.handler.desktop";

      "text/plain" = "code.desktop";
      "text/markdown" = "code.desktop";
      "text/x-markdown" = "code.desktop";

      "application/json" = "code.desktop";
      "application/x-yaml" = "code.desktop";
      "text/yaml" = "code.desktop";
      "text/x-yaml" = "code.desktop";
      "application/toml" = "code.desktop";
      "text/x-toml" = "code.desktop";
      "application/xml" = "code.desktop";
      "text/xml" = "code.desktop";
      "text/x-ini" = "code.desktop";
      "text/x-properties" = "code.desktop";

      "application/x-shellscript" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "application/x-bash" = "code.desktop";
      "text/x-python" = "code.desktop";
      "application/x-python-code" = "code.desktop";
      "text/x-lua" = "code.desktop";

      "text/x-c" = "code.desktop";
      "text/x-csrc" = "code.desktop";
      "text/x-chdr" = "code.desktop";
      "text/x-c++" = "code.desktop";
      "text/x-c++src" = "code.desktop";
      "text/x-c++hdr" = "code.desktop";
      "text/x-rust" = "code.desktop";
      "text/rust" = "code.desktop";
      "text/x-go" = "code.desktop";
      "text/javascript" = "code.desktop";
      "application/javascript" = "code.desktop";
      "text/typescript" = "code.desktop";
      "application/typescript" = "code.desktop";
      "text/css" = "code.desktop";
      "text/x-scss" = "code.desktop";
      "text/x-sql" = "code.desktop";

      "text/x-diff" = "code.desktop";
      "text/x-patch" = "code.desktop";
      "text/x-dockerfile" = "code.desktop";
      "text/x-makefile" = "code.desktop";
      "text/x-cmake" = "code.desktop";

      "application/pdf" = "org.kde.okular.desktop";

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

      "inode/directory" = "org.kde.dolphin.desktop";
      "application/zip" = "org.kde.ark.desktop";
      "application/x-tar" = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/vnd.rar" = "org.kde.ark.desktop";

      "x-scheme-handler/geo" = "google-maps-geo-handler.desktop";
    };
  };
}
