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
  nt,
  lib,
  config,
  ...
}: let
  inherit
    (builtins)
    mapAttrs
    ;

  inherit
    (nt)
    flip
    ;

  cfg = config.pkgsrc;
in {
  options.pkgsrc = lib.mkOption {
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

  config = let
    # TODO: use lib.types.submodule to restrict what options
    # TODO: can be given to pkgsrc
    repos =
      cfg
      |> mapAttrs (
        name: args:
          assert args ? source
          || abort ''
            ${./.}
            `pkgsrc.${name} missing required attribute "source"`
          '';
            args
            |> flip removeAttrs ["source"]
            |> import args.source
      );
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    # "pkgs" is unique since the nix module system already handles it
    _module.args =
      removeAttrs repos ["pkgs"];

    # nixpkgs =
    #   lib.mkIf (cfg ? pkgs)
    #   (let
    #     pkgs = cfg.pkgs;
    #   in
    #     lib.mkForce (
    #       (removeAttrs pkgs ["source"])
    #       // {
    #         flake.source = pkgs.source;
    #       }
    #     ));
  };
}
