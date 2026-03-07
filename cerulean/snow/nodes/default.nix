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
  lib,
  specialArgs,
  ...
}: {
  options.nodes = let
    inherit
      (lib)
      mkOption
      types
      ;
  in
    mkOption {
      description = ''
        Cerulean node declarations.
      '';
      type = types.submoduleWith {
        inherit specialArgs;

        modules = [
          {
            imports = [./shared.nix];

            options = {
              groups = mkOption {
                type = types.attrs;
                default = {};
                example = lib.literalExpression "{ servers = { staging = {}; production = {}; }; }";
                description = ''
                  Hierarchical groups that nodes can be a member of.
                '';
              };

              nodes = mkOption {
                type = types.attrsOf (types.submoduleWith {
                  inherit specialArgs;
                  modules = [(import ./submodule.nix)];
                });
                # example = { ... }; # TODO
                description = ''
                  Node (host systems) declarations.
                '';
              };
            };
          }
        ];
      };
    };
}
