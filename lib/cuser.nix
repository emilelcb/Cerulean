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
