# Copyright 2026 Emile Clark-Boman
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
  system,
  config,
  contextName,
  ...
}: let
  inherit
    (builtins)
    mapAttrs
    ;

  cfg = config.nixpkgs.channels;
in {
  options.nixpkgs.channels = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrs);
    default = {};
    description = "Declare package repositories per module context (nixos, home-manager, etc)";
    example = {
      "homes" = {
        "pkgs" = {
          source = "inputs.nixpkgs";
          system = "x86-64-linux";
          config = {
            allowUnfree = true;
            allowBroken = false;
          };
        };
        "upkgs" = {
          source = "inputs.nixpkgs-unstable";
          system = "x86-64-linux";
          config = {
            allowUnfree = true;
            allowBroken = false;
          };
        };
      };
    };
  };

  # or abort ''
  #         `nixpkgs.channels.${contextName}` does not exist, but neither does `nixpkgs.channels.default`!
  #         A channel configuration must be declared for module context "${contextName}".
  #       ''

  config = let
    # TODO: use lib.types.submodule to restrict what options
    # TODO: can be given to `nixpkgs.channels.${moduleName}.${name}`
    decl =
      cfg.${contextName} or cfg.default;

    repos =
      decl
      |> mapAttrs (
        name: args:
          assert args ? source
          || abort ''
            ${toString ./.}
            `nixpkgs.channels.${contextName}.${name} missing required attribute "source"`
          '';
            ((removeAttrs args ["source"])
              // {inherit system;})
            |> import args.source
            |> lib.mkOverride 200
      );
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    # "pkgs" is unique since the nix module system already handles it
    _module.args = removeAttrs repos ["pkgs"];

    nixpkgs =
      if contextName == "hosts"
      then {flake.source = lib.mkIf (decl ? pkgs) (lib.mkOverride 200 decl.pkgs.source);}
      else {};
  };
}
