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
  pkgs,
  system,
  _cerulean,
  ...
} @ args: {
  imports = with _cerulean.inputs;
    [
      # add support for `options.legacyImports`
      # ./legacy-imports.nix

      # user configuration
      (import /${root}/nixpkgs.nix)
      # options declarations
      (import ./nixpkgs.nix (args // {contextName = "hosts";}))

      sops-nix.nixosModules.sops
      # microvm.nixosModules.microvm
    ]
    ++ (
      if _cerulean.homeManager != null
      then [./home.nix]
      else []
    );

  environment.systemPackages =
    (with pkgs; [
      sops
    ])
    ++ (with _cerulean.inputs; [
      deploy-rs.packages.${system}.default
    ]);
}
