{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
} @ args: let
  getModule = name: "../modules/homemanager/${name}.nix";
  getModules = map (x: getModule x);
in {
  imports = getModules [
    "term/foot"
    "editor/vscode"

    "wm/hyprland"
    "wm/hyprland/hyprlock"

    "dm/sddm"
    "dm/sddm/themes/corners"

    "apps/firefox"
    "apps/thunderbird"
    "apps/obsidian"
    "apps/rider"
    "apps/winbox"
    "apps/gitkraken"
    "apps/thunar"

    "wm/kanshi"
    "wm/mako"
  ];

  home = {
    pointerCursor = {
      gtk.enable = true;
      # x11.enable = true # dont enable since im on hyprland
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 16;
    };

    packages = with pkgs; [
      # for services.gnome-keyring
      (
        if config.cerulean.isGraphical
        then seahorse # gui
        else null
      )

      fuzzel
    ];
  };

  gtk = {
    enable = true;
    font.name = "Victor Mono SemiBold 12";
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
    };
    # TODO: use a variable to mirror this cursor size
    #       with the `home.pointerCurser.size`
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 16;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk2";
    style.name = "gtk2";
  };

  services = {
    # Set display manager (login screen)
    displayManager = {
      # sddm relies on pkgs.libsForQt5.qt5.qtgraphicaleffects
      sddm = {
        enable = true;
        wayland.enable = true; # experimental
        theme = "corners";
      };
      defaultSession =
        "hyprland"
        + (
          if config.programs.hyprland.withUWSM
          then "-uwsm"
          else null
        );
    };

    # Multimedia Framework
    # With backwards compatability for alsa/pulseaudio/jack
    pipewire = {
      enable = true;
      wireplumber.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  # ---- ENVIRONMENT ----
  environment = {
    sessionVariables = {
      # Hint Electron apps to use support Wayland
      NIXOS_OZONE_WL = "1";
    };
  };

  # ---- SYSTEM PACKAGES ----
  environment.systemPackages = with pkgs; [
    # User Environment
    swww
    helvum
    easyeffects
    pavucontrol
    hyprpicker # colour picking utility
    hyprshot # screenshot utility
    qbittorrent
    signal-desktop # MAKE THIS ONLY FOR THE DESKTOP FOR END USERS, NOT SERVERS
    kdePackages.gwenview # image viewer
    libreoffice
    wl-clipboard # clipboard for wayland
  ];

  security.rtkit.enable = true; # I *think* this is for pipewire
}
