# Copyright 2025-2026 _cry64 (Emile Clark-Boman)
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
  base,
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
    type = lib.types.attrs;
    default = {};
    description = "Declare package repositories";
    example = {
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
          allowUnfree = false;
          allowBroken = true;
        };
      };
    };
  };

  config = let
    repos =
      cfg
      |> (xs: removeAttrs xs ["default"])
      |> mapAttrs (
        name: args:
          lib.mkForce (
            assert args ? source
            || abort ''
              `nixpkgs.channels.${name}` missing required attribute "source"
            '';
              import args.source ({inherit system;} // (removeAttrs args ["source"]))
          )
      );

    # XXX: TODO: would it work to use `base` instead of having default?
    defaultPkgs =
      cfg.default or (throw ''
        Your `nixpkgs.nix` file does not declare a default package source.
        Ensure you set `nixpkgs.channels.*.default = ...;`
      '');
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    # WARNING: pkgs is a reserved specialArg
    _module.args = removeAttrs repos ["pkgs" "default"];

    nixpkgs =
      if contextName == "hosts"
      then {
        flake.source = lib.mkForce base; # DEBUG: temp while getting base to work
        overlays = lib.mkForce (defaultPkgs.overlays or {});
        config = lib.mkForce (defaultPkgs.config or {});
      }
      else if contextName == "homes"
      then {
        config = lib.mkForce (defaultPkgs.config or {});
        overlays = lib.mkForce (defaultPkgs.overlays or []);
      }
      else {};
  };
}
