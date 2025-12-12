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
    "shell/fish"

    "cli/git"
    "cli/bat"
    "cli/btop"
    "cli/tmux"

    "editor/helix"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.GetName pkg) [
      "vscode-extension-ms-dotnettools-csharp"
    ];

  home = {
    stateVersion = config.cerulean.stateVersion; # DO NOT MODIFY

    username = config.cerulean.username;
    homeDirectory = "/home/${config.cerulean.username}";

    shellAliases = {
      rg = "batgrep"; # bat + ripgrep
      man = "batman"; # bat + man
    };

    sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = 1;
    };

    packages = with pkgs; [
      # for services.gnome-keyring
      gcr # provides org.gnome.keyring.SystemPrompter
      speedtest-cli
    ];
  };

  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        ignoreAllDups = true;
        path = "$HOME/.zsh_history";
        ignorePatterns = [
          "rm *"
        ];
      };
    };

    # set ssh profiles
    # NOTE: (IMPORTANT) this DOES NOT start the ssh-agent
    #       for that you need to use `services.ssh-agent.enable`
    ssh = {
      enable = true;
      forwardAgent = false;
      addKeysToAgent = "no";
    };
  };

  services = {
    # enable OpenSSH private key agent
    ssh-agent.enable = true;

    gnome-keyring.enable = true;
  };

  # the ssh-agent won't set this for itself...
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
