{ config
, pkgs
, inputs
, lib
, ...
}:

{
  # ============================================================================
  # 1. MODULE IMPORTS
  # ============================================================================
  imports = [
    # Declarative Flatpak management for user profiles
    inputs.nix-flatpak.homeManagerModules.nix-flatpak

    # Declarative KDE Plasma 6 desktop configuration (panels, widgets, KWin rules)
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  # ============================================================================
  # 2. USER IDENTITY & STATE VERSION
  # ============================================================================
  home = {
    username = "fumoctl";
    homeDirectory = "/home/fumoctl";
    stateVersion = "26.05"; #Dont modify this once the system is installed
  };

  # ============================================================================
  # 3. USER PACKAGES
  # ============================================================================
  home.packages = with pkgs; [
    # Modern GNOME container-ready terminal emulator with tabbed interface
    unstable.ptyxis

    # Host-side native messaging connector for browser integration
    kdePackages.plasma-browser-integration

    # Modern cursor theme matching KDE configuration
    bibata-cursors
  ];

  # ============================================================================
  # 4. SSH & SECURITY CONFIGURATION
  # ============================================================================
  # OpenSSH strictly rejects configuration files with permissive file modes.
  # Since Nix store symlinks are world-readable, we write to a source file and copy
  # it into place with strict 0600 permissions upon any configuration changes.
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

  # ============================================================================
  # 5. VERSION CONTROL (GIT & GITHUB CLI)
  # ============================================================================
  programs.git = {
    enable = true;

    # Cryptographic commit signing
    signing = {
      key = "35FAC098F119E8FA";
      signByDefault = true; # Enforce signed commits by default
    };

    settings = {
      user = {
        name = "JuanU";
        email = "juanu@fumoctl.com";
      };
    };
  };

  # GitHub command-line interface with OAuth credential helper
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # ============================================================================
  # 6. SHELL & TERMINAL (ZSH & PTYXIS)
  # ============================================================================
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

  # Custom desktop entry for Ptyxis terminal to enable "Open Terminal Here" in Dolphin
  xdg.desktopEntries."org.gnome.Ptyxis" = {
    name = "Ptyxis";
    genericName = "Terminal";
    comment = "A terminal for GNOME";
    # %U passes the current working directory URI from Dolphin/KDE
    exec = "ptyxis --new-window %U";
    icon = "org.gnome.Ptyxis";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    startupNotify = true;
  };

  # Ptyxis terminal preferences: disable automatic session restoration so windows open clean
  dconf.settings = {
    "org/gnome/Ptyxis" = {
      restore-session = false;
    };
  };

  # ============================================================================
  # 7. CODE EDITOR (VISUAL STUDIO CODE)
  # ============================================================================
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Keep the extensions directory mutable so extensions can be installed/updated
    # directly via VS Code marketplace or VSIX without getting wiped on rebuild
    mutableExtensionsDir = true;
  };

  # ============================================================================
  # 8. WEB BROWSER (BRAVE & PLASMA INTEGRATION)
  # ============================================================================
  programs.brave = {
    enable = true;
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass (Password manager)
      { id = "cimiefiiaegbelhefglklhhakcgmhkai"; } # Plasma Integration (Media controls & downloads)
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # Decentraleyes (Local CDN emulation)
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger (Heuristic tracker blocker)
    ];
  };

  # Native messaging host bridge for Brave to communicate with KDE Plasma system tray & media keys
  xdg.configFile."BraveSoftware/Brave-Browser/NativeMessagingHosts/org.kde.plasma.browser_integration.json".source =
    "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  # ============================================================================
  # 9. DECLARATIVE FLATPAK MANAGEMENT & RUNTIME OVERRIDES
  # ============================================================================
  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"      # Flatpak permission management GUI
      "com.obsproject.Studio"           # Video recording and live streaming
      "com.usebottles.bottles"          # Wine prefix & gaming environment manager
      "com.vysp3r.ProtonPlus"           # Proton, Wine, and DXVK version manager
      "com.github.Matoking.protontricks" # Winetricks GUI/CLI for Steam Proton
      "com.ranfdev.DistroShelf"         # Distrobox graphical container manager
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
    uninstallUnmanaged = false;
  };

    home.file.".local/share/themes/catppuccin-mocha-mauve-standard".source =
    "${pkgs.catppuccin-gtk.override { accents = [ "mauve" ]; variant = "mocha"; }}/share/themes/catppuccin-mocha-mauve-standard";

  home.activation = {
    # Configure language preference priority for Flatpak runtimes
    configureFlatpakLanguages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';

    # Fix OBS Studio Qt plugin crashes by scrubbing host-inherited Qt environment variables
    fixobsqt = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.flatpak}/bin/flatpak override --user --unset-env=QT_PLUGIN_PATH --unset-env=LD_LIBRARY_PATH --unset-env=QT_QPA_PLATFORM_PLUGIN_PATH com.obsproject.Studio
    '';

    # Grant Bottles full home directory filesystem access for managing custom prefixes and game folders
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
        --env=GTK_THEME=catppuccin-mocha-mauve-standard \
        --env=ICON_THEME=breeze-dark
    '';
  };

  # ============================================================================
  # 10. GTK THEME CONSISTENCY (FOR NON-QT APPLICATIONS)
  # ============================================================================
  # Ensures GTK applications (such as Ptyxis terminal and file pickers) adhere
  # to the same dark palette, Breeze-Dark icons, and Bibata cursor theme.
  gtk = {
    enable = true;
    gtk2.enable = false; # Disables ~/.gtkrc-2.0 to eliminate conflicts with KDE Plasma's kde-gtk-config
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
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

  # ============================================================================
  # 11. KDE PLASMA 6 DECLARATIVE DESKTOP CONFIGURATION (PLASMA-MANAGER)
  # ============================================================================
  programs.plasma = {
    enable = true;
    overrideConfig = true; # Wipes unmanaged imperative KDE keys on login

    # --------------------------------------------------------------------------
    # WORKSPACE & THEMING
    # --------------------------------------------------------------------------
    workspace = {
      # Global look-and-feel package
      lookAndFeel = "org.kde.breezedark.desktop";

      # Color scheme (Catppuccin Mocha Mauve matching SDDM)
      colorScheme = "CatppuccinMochaMauve";

      # Icon theme
      iconTheme = "breeze-dark";

      # Cursor theme and geometry
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 20;
      };

      # Desktop background wallpaper
      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}";
    };

    # --------------------------------------------------------------------------
    # TYPOGRAPHY & DESKTOP FONTS
    # --------------------------------------------------------------------------
    fonts = {
      # Standard application UI font
      general = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      # Monospace font for code, terminal widgets, and editors
      fixedWidth = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };

      # Small UI elements, badges, and sublabels
      small = {
        family = "Noto Sans CJK JP";
        pointSize = 8;
      };

      # Toolbar button labels
      toolbar = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      # Application menu items and dropdowns
      menu = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };

      # Window titlebars
      windowTitle = {
        family = "Noto Sans CJK JP";
        pointSize = 10;
      };
    };

    # --------------------------------------------------------------------------
    # KWIN WINDOW MANAGER
    # --------------------------------------------------------------------------
    kwin = {
      # Virtual desktop workspace layout
      virtualDesktops = {
        number = 4;
        rows = 1;
      };

      # Window titlebar action buttons
      titlebarButtons = {
        left = [ "more-window-actions" ];
        right = [ "minimize" "maximize" "close" ];
      };

      # Window management effects
      effects = {
        blur.enable = true;
      };
    };

    # --------------------------------------------------------------------------
    # SCREEN LOCKER (KSCREENLOCKER)
    # --------------------------------------------------------------------------
    kscreenlocker = {
      autoLock = true;
      timeout = 10; # Lock after 10 minutes of inactivity
      lockOnResume = true;
      passwordRequired = true;
      passwordRequiredDelay = 0;
      appearance.wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath}";
    };

    # --------------------------------------------------------------------------
    # SESSION MANAGEMENT
    # --------------------------------------------------------------------------
    session = {
      sessionRestore = {
        restoreOpenApplicationsOnLogin = "startWithEmptySession";
      };
    };

    # --------------------------------------------------------------------------
    # PANELS & STATUS WIDGETS
    # --------------------------------------------------------------------------
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

    # --------------------------------------------------------------------------
    # SHORTCUTS (SPECTACLE & SYSTEM ACTIONS)
    # --------------------------------------------------------------------------
    spectacle.shortcuts = {
      captureEntireDesktop = "Meta+Print";
      captureRectangularRegion = "Meta+Shift+Print";
      captureActiveWindow = "Meta+Ctrl+Print";
      launch = "";
    };

    # --------------------------------------------------------------------------
    # LOW-LEVEL KDE CONFIGURATION (KCMINPUTRC, KDEGLOBALS, KWINRC)
    # --------------------------------------------------------------------------
    configFile = {
      # Flat mouse acceleration profile (1:1 direct sensor input)
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

      # Default preferred application handlers
      "kdeglobals"."General" = {
        TerminalApplication = "ptyxis";
        TerminalService = "org.gnome.Ptyxis.desktop";
        BrowserApplication = "brave-browser.desktop";
      };
      "kdeglobals"."KDE Connect" = {
        tel = "org.kde.kdeconnect.handler.desktop";
      };

      # Disable splash screen animation for immediate desktop presentation
      "ksplashrc"."KSplash" = {
        Engine = "none";
        Theme = "None";
      };

      # KWin window manager settings
      kwinrc = {
        Desktops.Number = 4;
        Desktops.Rows = 1;
        "Windows" = {
          # Instant focus-follows-mouse window activation
          "FocusPolicy" = "FocusFollowsMouse";
          "DelayFocusInterval" = 0;
        };
      };
    };
  };

  # ============================================================================
  # 12. XDG MIME ASSOCIATIONS & SHARED MIME DEFINITIONS
  # ============================================================================
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # --- Web, Mail & Telephony ---
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "x-scheme-handler/tel" = "org.kde.kdeconnect.handler.desktop";

      # --- Code, Markdown & Text Editing (VS Code) ---
      "text/plain" = "code.desktop";
      "text/markdown" = "code.desktop";
      "text/x-markdown" = "code.desktop";

      # Configuration & Markup
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

      # Shell & Scripts
      "application/x-shellscript" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "application/x-bash" = "code.desktop";
      "text/x-python" = "code.desktop";
      "application/x-python-code" = "code.desktop";
      "text/x-lua" = "code.desktop";

      # Compiled & Web Programming Languages
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

      # Build & Patch Formats
      "text/x-diff" = "code.desktop";
      "text/x-patch" = "code.desktop";
      "text/x-dockerfile" = "code.desktop";
      "text/x-makefile" = "code.desktop";
      "text/x-cmake" = "code.desktop";

      # --- Documents & E-Books ---
      "application/pdf" = "org.kde.okular.desktop";

      # --- Image Viewers ---
      "image/png" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";

      # --- Audio Players ---
      "audio/mpeg" = "org.kde.elisa.desktop";
      "audio/flac" = "org.kde.elisa.desktop";
      "audio/x-vorbis+ogg" = "org.kde.elisa.desktop";

      # --- Video Players ---
      "video/mp4" = "umpv.desktop";
      "video/mkv" = "umpv.desktop";
      "video/webm" = "umpv.desktop";
      "video/x-matroska" = "umpv.desktop";

      # --- File Manager & Archive Utilities ---
      "inode/directory" = "org.kde.dolphin.desktop";
      "application/zip" = "org.kde.ark.desktop";
      "application/x-tar" = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/vnd.rar" = "org.kde.ark.desktop";

      # --- Geographic Navigation ---
      "x-scheme-handler/geo" = "google-maps-geo-handler.desktop";
    };
  };
}
