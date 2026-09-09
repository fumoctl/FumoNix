{ config
, lib
, pkgs
, inputs
, ...
}:

{
  # ============================================================================
  # 1. MODULE IMPORTS
  # ============================================================================
  imports = [
    # Declarative system-wide theming engine for NixOS & Home Manager
    inputs.stylix.nixosModules.stylix
  ];

  # ============================================================================
  # 2. CORE SYSTEM THEMING & COLOR PALETTE
  # ============================================================================
  stylix = {
    enable = true;

    # Color tone polarity: hints downstream applications (GTK/Qt/browsers) to prefer dark mode
    polarity = "dark";

    # Base16 color scheme: Tokyo Night Dark
    # Base16 standardizes a 16-color palette across terminal emulators, editors, and UI frameworks,
    # allowing Stylix to systematically generate coordinated styles from a single YAML definition.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    # Global wallpaper asset:
    # Stylix propagates this image to the desktop background, SDDM/lockscreen, and Limine bootloader.
    # Can be replaced with a local relative path, e.g. ./wallpapers/custom-wallpaper.png
    image = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
    imageScalingMode = "fill";

    # ==========================================================================
    # 3. CURSOR THEME & GEOMETRY
    # ==========================================================================
    cursor = {
      # Modern, rounded cursor theme with high contrast
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      # Size 20 provides crisp scaling on standard FHD and high-DPI displays
      size = 20;
    };

    # ==========================================================================
    # 4. TYPOGRAPHY & FONT HIERARCHY
    # ==========================================================================
    fonts = {
      # Monospace font with programming ligatures and developer glyphs
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      # Sans-Serif font with CJK Japanese glyph coverage to prevent broken character fallbacks
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK JP";
      };

      # Serif font for document reading and formal typography
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK JP";
      };

      # Full-color emoji glyphs
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      # Proportional font point sizes across different desktop UI layers
      sizes = {
        applications = 10; # Standard desktop application text (menus, dialogs)
        terminal = 11;     # Terminal emulator font size
        desktop = 10;      # Desktop environment labels and widgets
        popups = 10;       # Notifications, tooltips, and floating popups
      };
    };

    # ==========================================================================
    # 5. SYSTEM & BOOTLOADER TARGETS
    # ==========================================================================
    targets = {
      # Apply coordinated theme and wallpaper to the Limine EFI bootloader menu
      limine.enable = true;
    };
  };

  # ============================================================================
  # 6. USER & DESKTOP ENVIRONMENT THEMING (HOME MANAGER)
  # ============================================================================
  # Stylix configurations passed into Home Manager for user-session applications
  home-manager.sharedModules = [
    {
      # Enable native KDE Plasma 6 theming (colors, look-and-feel, wallpaper, cursor, fonts)
      stylix.targets.kde.enable = true;

      # Enable GTK theming for GNOME/GTK applications (e.g. Ptyxis terminal, file pickers)
      stylix.targets.gtk.enable = true;

      # Propagate generated GTK stylesheets and color definitions into Flatpak sandboxes
      stylix.targets.gtk.flatpakSupport.enable = true;

      # Opt-out: Do not overwrite user-configured VS Code marketplace themes
      stylix.targets.vscode.enable = false;

      # Opt-out: Disable standalone Qt theming (qt5ct/qt6ct/Kvantum) to avoid
      # conflicting with KDE Plasma's internal Qt styling engine and evaluation warnings
      stylix.targets.qt.enable = false;
    }
  ];
}
