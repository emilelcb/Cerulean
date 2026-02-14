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

  config = let
    # TODO: use lib.types.submodule to restrict what options
    # TODO: can be given to `nixpkgs.channels.${moduleName}.${name}`
    decl =
      cfg.${contextName} or cfg.default;

    repos =
      decl
      |> mapAttrs (
        name: args:
          lib.mkForce (
            assert args ? source
            || abort ''
              ${toString ./.}
              `nixpkgs.channels.${contextName}.${name}` missing required attribute "source"
            '';
              ((removeAttrs args ["source"])
                // {inherit system;})
              |> import args.source
          )
      );
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    _module.args = repos;

    nixpkgs = let
      defaultPkgs =
        decl.default or (throw ''
          Your `nixpkgs.nix` file does not declare a default package source.
          Ensure you set `nixpkgs.channels.*.default = ...;`
        '');
    in
      if contextName == "hosts"
      then {
        flake.source = lib.mkOverride 200 defaultPkgs.source;
        config = lib.mkOverride 200 defaultPkgs.config;
      }
      else if contextName == "homes"
      then {
        # XXX: XXX: XXX: OH OH OH OMG, its because aurora never defines pkgs
        config = lib.mkOverride 200 (defaultPkgs.config or {});
        # XXX: WARNING: TODO: modify options so overlays must always be given as the correct type
        overlays = lib.mkOverride 200 (defaultPkgs.overlays or []);
      }
      else {};
  };
}
