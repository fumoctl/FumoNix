{ pkgs
, inputs
, config
, ...
}:

{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    polarity = "dark";

    # Base16 color scheme: Tokyo Night Dark
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    # Wallpaper image:
    # Stylix uses this for the desktop background and Limine bootloader.
    # To use a custom wallpaper, replace this with a local path like ./wallpapers/my-wallpaper.png
    image = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
    imageScalingMode = "fill";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 20;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK JP";
      };
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK JP";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 10;
        terminal = 11;
        desktop = 10;
        popups = 10;
      };
    };

    targets = {
      # Theming for Limine bootloader
      limine.enable = true;
    };
  };

  # Home Manager targets:
  # - Explicitly enable KDE Plasma 6 theming (LookAndFeel, color schemes, wallpaper, fonts, cursor).
  # - Keep GTK applications themed (Ptyxis, etc.).
  # - Exclude VSCode from being themed by Stylix so you can manage extensions/themes freely.
  # - Disable standalone qt target (designed for qtct/kvantum) to prevent evaluation warnings in KDE.
  home-manager.sharedModules = [
    {
      stylix.targets.kde.enable = true;
      stylix.targets.gtk.enable = true;
      stylix.targets.gtk.flatpakSupport.enable = true;
      stylix.targets.vscode.enable = false;
      stylix.targets.qt.enable = false;
    }
  ];
}
