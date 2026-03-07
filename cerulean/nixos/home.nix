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
  _cerulean,
  config,
  root,
  lib,
  ...
} @ args: let
  inherit
    (builtins)
    pathExists
    ;

  inherit
    (lib)
    filterAttrs
    mapAttrs
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
      useUserPackages = lib.mkDefault false;
      useGlobalPkgs = lib.mkDefault true;

      overwriteBackup = lib.mkDefault false;
      backupFileExtension = lib.mkDefault "bak";

      users =
        config.users.users
        |> filterAttrs (name: value: value.manageHome && pathExists /${root}/homes/${name})
        |> mapAttrs (name: _: {...}: {
          imports = [/${root}/homes/${name}];

          # per-user arguments
          _module.args.username = name;
        });

      extraSpecialArgs = _cerulean.specialArgs;
      sharedModules = [
        ../home

        (import /${root}/nixpkgs.nix)
        # options declarations
        (import ./nixpkgs.nix (args // {contextName = "homes";}))
      ];
    };
  };
}
