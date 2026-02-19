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
{lib, ...}: let
  inherit
    (lib)
    mkOption
    types
    ;

  flakeRef = types.either types.str types.path;
in {
  options = {
    base = lib.mkOption {
      # In newer Nix versions, particularly with lazy trees, outPath of
      # flakes becomes a Nix-language path object. We deliberately allow this
      # to gracefully come through the interface in discussion with @roberth.
      #
      # See: https://github.com/NixOS/nixpkgs/pull/278522#discussion_r1460292639
      type = types.nullOr flakeRef;

      default = null;
      defaultText = "if (using nixpkgsFlake.lib.nixosSystem) then self.outPath else null";

      example = lib.literalExpression "inputs.nixpkgs";

      description = ''
        The path to the nixpkgs source used to build a system. A `base` package set
        is required to be set, and can be specified via either:
        1. `options.nodes.base` (default `base` used for all systems)
        2. `options.nodes.nodes.<name>.base` (takes prescedence over `options.nodes.base`)

        This can also be optionally set if the NixOS system is not built with a flake but still uses
        pinned sources: set this to the store path for the nixpkgs sources used to build the system,
        as may be obtained by `fetchTarball`, for example.

        Note: the name of the store path must be "source" due to
        <https://github.com/NixOS/nix/issues/7075>.
      '';
    };

    modules = mkOption {
      type = types.listOf types.raw;
      default = [];
      example = lib.literalExpression "[ { environment.systemPackages = [ pkgs.git ]; } ]";
      description = ''
        Shared modules to import; equivalent to the NixOS module system's `extraModules`.
      '';
    };

    args = mkOption {
      type = types.attrs;
      default = {};
      example = lib.literalExpression "{ inherit inputs; }";
      description = ''
        Shared args to provided for each node; equivalent to the NixOS module system's `specialArgs`.
      '';
    };

    homeManager = mkOption {
      type = types.nullOr flakeRef;
      default = null;
      example = lib.literalExpression "inputs.home-manager";
      description = ''
        The path to the home-manager source. A `homeManager` flake reference
        is required to be set for `homes/` to be evaluated, and can be specified via either:
        1. `options.nodes.homeManager` (default `homManager` used for all systems)
        2. `options.nodes.nodes.<name>.homeManager` (takes prescedence over `options.nodes.homeManager`)
      '';
    };
  };
}
