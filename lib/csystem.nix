# Copyright 2025 Emile Clark-Boman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
{
  inputs,
  lib,
  config,
  pkgs,
  pkgs-unstable,
  homemanager,
  cerulean,
  ...
} @ args: let
  getModule = name: "../modules/nixos/${name}.nix";
  getModules = map (x: getModule x);

  getHostModule = name: "TODO";
in {
  imports = getModules [
    (getHostModule "hardware-configuration")
    (import "${homemanager}/nixos")

    "shell/bash"
    "shell/bash/bashistrans.nix"
    "shell/zsh"
    "shell/fish"

    "cli/git"
    "cli/bat"
    "cli/btop"
    "cli/tmux"
    "cli/nvim"

    "lang/asm"
    "lang/bash" # TODO: (YES THIS IS DIFFERENT TO shell/bash, this provides language support ie pkgs.shellcheck)
    "lang/c-family"
    "lang/dotnet"
    # "lang/go"
    # "lang/haskell"
    # "lang/java"
    # "lang/nim"
    "lang/python"
    # "lang/rust"
    # "lang/sage"

    "editor/helix"
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    download-buffer-size = 524288000; # 500 MiB

    # making wheel group members "trusted users" allows
    # them to import packages not signed by a trusted key
    # (aka super duper easier to remote deploy)
    trusted-users = ["root" "@wheel"];
  };

  nixpkgs = {
    overlays = cerulean.lib.importOverlaysNixOS;

    config = if config.cerulean.allowUnfreeWhitelist != []
             then {
               allowUnfreePredicate =
                 pkg: builtins.elem
                   (lib.getName pkg)
                   config.cerulean.allowUnfreeWhitelist;
             }
             else {
               allowUnfree = config.cerulean.allowUnfree;
             };
  };

  # colmena deployment configuration
  deployment = {
    targetHost = config.cerulean.domain ?? config.cerulean.ip;
    targetUser = "cerulean";
    targetPort = "22";
    sshOptions = [
      "-A" # forward ssh-agent
    ];
    buildOnTarget = false; # build locally then deploy
  };


  time.timeZone = config.cerulean.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable initrd hook for virtual console customisation
  # aka cool colours when booting yay!!
  console = {
    enable = true;
    earlySetup = true; # initrd pre hook
    keyMap = "us";
    font = "Lat2-Terminus16";
        # ANSI 24-bit color definitions (theme: dracula)
    colors = [
      "21222c"
      "ff5555"
      "50fa7b"
      "f1fa8c"
      "bd93f9"
      "ff79c6"
      "8be9fd"
      "f8f8f2"
      "6272a4"
      "ff6e6e"
      "69ff94"
      "ffffa5"
      "d6acff"
      "ff92df"
      "a4ffff"
      "ffffff"
    ];
  };

  # super duper minimum grub2 config
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    
    grub = {
      enable = true;
      device = "nodev";
    };

        # GitHub: vinceliuice/grub2-themes
    grub2-theme = {
      enable = true;
      theme = "whitesur"; # stylish, vimix, or whitesur
      footer = true;
      # TODO: switch my cables to switch default grub display
      customResolution = "3840x2160";
    };
  };
  
  networking = {
    hostName = config.cerulean.hostname;
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22  # sshd
        80  # nginx (http)
        443 # nginx (https)
        # 5678 # MikroTik WinBox
      ];
    };
  };

  # ------- USERS -------
  security.sudo.wheelNeedsPassword = true;
  users = {
    defaultUserShell = pkgs.bash;

    users = cerulean.lib.importUsersNixOS;
  };

  home-manager = {
    users = cerulean.lib.importUsersHomeManager;

    extraSpecialArgs = { inherit inputs pkgs pkgs-unstable; };
    sharedModules = [];
  };

  # ---- ENVIRONMENT ----
  environment = {
    # always install "dev"/"man" derivation outputs
    extraOutputsToInstall = ["dev" "man"];

    systemPackages = with pkgs; [
      # User Environment
      bluetui

          # Shell
    bash
    fish
    shellcheck
    grc # colorise command outputs
    moreutils

    # Systems Programming & Compilation
    qemu # Fellice Bellard's Quick Emulator
    # GNU Utils
    gnumake
    # Binaries
    binutils
    strace
    ltrace
    perf-tools # ftrace + perf
    radare2
    gdb
    # ASM
    nasm
    (callPackage ../packages/x86-manpages {})
    # C Family
    gcc
    clang
    clang-tools

    # Rust
    cargo
    rustc
    # Go
    go
    # Nim
    nim
    nimble
    # Haskell
    ghc
    ghcid
    haskell-language-server
    ormolu

    # Python
    python312 # I use 3.12 since it's in a pretty stable state now
    python314 # also 3.14 for latest features
    poetry

    openvpn
    inetutils

    # security tools
    nmap

    httpie
    curlie
    zoxide
    doggo
    tldr
    btop
    eza
    yazi
    lazygit
    ripgrep
    viddy # modern `watch` command
    thefuck

    # TODO: once upgraded past Nix-24.07 this line won't be necessary (I think)
    #       helix will support nixd by default
    # SOURCE: https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md#Helix
    # nixd # lsp for nix # DEBUG

    # Pretty necessary
    nix-prefetch-git
    brightnessctl
    acpi
    powertop
    imagemagick

    # "Standard" Unix Commands
    vim
    file
    wget
    tree
    pstree
    unzip
    unrar-free
    lz4
    man-pages
    man-pages-posix

    # Cryptography
    gnupg
    openssl
    libargon2
    ];
  };
  
  programs = {
    nix-ld.enable = true;
  };

  documentation = {
    enable = true;
    doc.enable = true; # install /share/doc packages
    man.enable = true; # install manpages
    info.enable = true; # install GNU info
    dev.enable = true; # install docs intended for developers
    nixos = {
      enable = true; # install NixOS documentation (ie man -k nix, & nixos-help)
      options.splitBuild = true;
      # includeAllModules = true;
    };
  };
  
  virtualisation.docker.enable = true;
  

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth = let
      btSupported = config.cerulean.bluetoothSupported;
    in {
      enable = btSupported;
      powerOnBoot = btSupported;
    };
  };

  system.stateVersion = config.cerulean.stateVersion; # DO NOT MODIFY
}
