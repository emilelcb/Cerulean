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
      "npkgs" = {
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
      |> (xs: removeAttrs xs ["base"])
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

    basePkgs = cfg.base or {};
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    # WARNING: pkgs is a reserved specialArg
    _module.args = removeAttrs repos ["pkgs" "base"];

    nixpkgs = let
      nixpkgConfig = {
        config = lib.mkForce (basePkgs.config or {});
        overlays = lib.mkForce (basePkgs.overlays or []);
      };
    in
      if contextName == "hosts"
      then
        nixpkgConfig
        // {
          flake.source = lib.mkForce base;
        }
      else if contextName == "homes"
      then nixpkgConfig
      else {};
  };
}
