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
  root,
  config,
  lib,
  _cerulean,
  ...
} @ args: let
  inherit
    (builtins)
    attrNames
    filter
    pathExists
    ;
in {
  imports = [
    _cerulean.homeManager.nixosModules.default
  ];

  options = {
    users.users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.manageHome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          example = false;
          description = ''
            Whether Cerulean should automatically enable home-manager for this user,
            and manage their home configuration declaratively.

            Enabled by default, but can be disabled if necessary.
          '';
        };
      });
    };
  };

  config = {
    home-manager = {
      users =
        config.users.users
        |> attrNames
        |> filter (x: x.manageHome && pathExists /${root}/homes/${x})
        |> (x:
          lib.genAttrs x (y:
            import /${root}/homes/${y}));

      extraSpecialArgs = _cerulean.specialArgs;
      sharedModules = [
        ../home

        # user configuration
        (import /${root}/nixpkgs.nix)
        # options declarations
        (import ./nixpkgs.nix (args // {contextName = "homes";}))
      ];
    };
  };
}
