# Copyright 2025 Emile Clark-Boman
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
  description = "Your Nix Cloud Simplified";

  inputs = {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nib = {
      # url = "github:emilelcb/nib";
      url = "/home/me/agribit/nexus/nib";
      inputs.systems.follows = "systems";
    };

    # mix.url = "github:emilelcb/mix";
    mix.url = "/home/me/agribit/nexus/mix";

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nib,
    ...
  } @ inputs: let
    inherit
      (nixpkgs)
      lib
      ;

    sys = nib.mkUSys {
      pkgs = nib.withPkgs nixpkgs {
        config.allowUnfree = false;
        overlays = builtins.attrValues self.overlays;
      };
      upkgs = nib.withPkgs nixpkgs-unstable {
        config.allowUnfree = false;
      };
    };
  in
    import ./cerulean <| inputs // {inherit lib sys;};
}
