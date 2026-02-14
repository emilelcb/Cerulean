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
    typeOf
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
          lib.mkForce (
            # builtins.trace "SAVE ME GOT NAME: ${name}" (
            assert args ? source
            || abort ''
              ${toString ./.}
              `nixpkgs.channels.${contextName}.${name}` missing required attribute "source"
            '';
              ((removeAttrs args ["source"])
                // {inherit system;})
              |> import args.source
            # DEBUG: |> lib.mkOverride 200
          )
        # )
      );
  in {
    # NOTE: _module.args is a special option that allows us to
    # NOTE: set extend specialArgs from inside the modules.
    # "pkgs" is unique since the nix module system already handles it
    # DEBUG: _module.args = lib.mkOverride 200 (
    # _module.args = (
    #   if contextName == "hosts"
    #   then repos
    #   else
    #     assert (
    #       repos
    #       |> builtins.attrNames
    #       |> map (x: "\"${x}\"")
    #       |> builtins.concatStringsSep " "
    #       |> (x: "FUCK YOU SO BAD: { ${x} }")
    #       |> abort
    #     );
    #       removeAttrs repos ["pkgs"]
    # );
    _module.args = repos;

    nixpkgs =
      if contextName == "hosts"
      then {flake.source = lib.mkIf (decl ? pkgs) (lib.mkOverride 200 decl.pkgs.source);}
      else if contextName == "homes"
      then {
        config = decl.pkgs.config or {};
        # XXX: WARNING: TODO: modify options so overlays must always be given as the correct type
        overlays = decl.pkgs.overlays or [];
      }
      else {};
  };
}
