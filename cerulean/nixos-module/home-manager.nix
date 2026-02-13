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
  root,
  config,
  lib,
  specialArgs,
  ...
} @ args: let
  inherit
    (builtins)
    attrNames
    filter
    pathExists
    ;
in {
  home-manager = {
    users =
      config.users.users
      |> attrNames
      |> filter (x: pathExists (root + "/homes/${x}"))
      |> (x: lib.genAttrs x (y: import (root + "/homes/${y}")));

    # extraSpecialArgs = specialArgs;
    sharedModules = [
      # user configuration
      # (import (root + "/nixpkgs.nix"))
      (import (root + "/nixpkgs.nix"))
      # options declarations
      # (import ./nixpkgs.nix (args // {contextName = "homes";}))
      (import ./nixpkgs.nix (args // {contextName = "homes";}))
    ];

    # disable home-manager trying anything fancy
    # we control the pkgs now!!
    # useGlobalPkgs = true;
  };
}
