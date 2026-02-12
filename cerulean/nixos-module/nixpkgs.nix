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
  config,
  ...
}: let
  cfg = config.pkgrepo;
in {
  options.pkgrepo = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = {};
    description = "Declare and import custom package repositories.";
    example = {
      "pkgs" = {
        source = "inputs.nixpkgs";
        system = "x86-64-linux";
        config = {
          allowUnfree = true;
          allowBroken = false;
        };
      };
    };
  };

  config.nixpkgs =
    lib.mkIf (cfg ? pkgs)
    (let
      pkgs = cfg.pkgs;
    in
      lib.mkForce (
        (builtins.removeAttrs pkgs ["source"])
        // {
          flake.source = pkgs.source;
        }
      ));
}
