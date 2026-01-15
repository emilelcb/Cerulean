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
  this,
  sys,
  nib,
  lib,
  deploy-rs,
  ...
}: let
  inherit
    (builtins)
    elem
    isAttrs
    mapAttrs
    pathExists
    typeOf
    ;

  inherit
    (this)
    mapNodes
    ;

  inherit
    (nib.std)
    getAttrOr
    ;

  templateNexus = let
    inherit
      (nib.types)
      Terminal
      ;

    missing = msg: path:
      Terminal (abort ''
        Each Cerulean Nexus node is required to specify ${msg}!
        Ensure `nexus.${path}` exists under your call to `cerulean.mkNexus`.
      '');
  in {
    root = missing "the root directory for all cerulean nix modules." "root";
    groups = missing "an list of all valid node group names." "groups";
    nodes = Terminal {};
  };

  parseNexus = nexus:
    if ! isAttrs nexus
    then
      abort ''
        Cerulean Nexus config must be provided as an attribute set, got "${typeOf nexus}" instead!
        Ensure all the `nexus` declaration is an attribute set under your call to `cerulean.mkNexus`.
      ''
    else nib.parse.overrideStruct templateNexus nexus;

  mkNexus' = nexus': let
    nexus = parseNexus nexus';
  in rec {
    nixosConfigurations = mapNodes nexus.nodes (
      nodeName: node:
        lib.nixosSystem {
          system = node.system;
          modules = let
            core' = nexus.root + "/hosts/${nodeName}";
            core =
              if pathExists core'
              then core'
              else core' + ".nix";
          in
            [core ../nixos-module] ++ node.extraModules;

          # nix passes these to every single module
          specialArgs =
            node.specialArgs
            // {
              pkgs = sys.pkgsFor node.system;
              upkgs = sys.upkgsFor node.system;
            };
        }
    );

    deploy.nodes = mapNodes nexus.nodes (nodeName: node: let
      inherit
        (node.deploy)
        activationTimeout
        autoRollback
        confirmTimeout
        interactiveSudo
        magicRollback
        remoteBuild
        ssh
        sudo
        user
        ;

      nixosFor = system: deploy-rs.lib.${system}.activate.nixos;
    in {
      hostname = ssh.host;

      profilesOrder = ["default"]; # profiles priority
      profiles.default = {
        path = nixosFor node.system nixosConfigurations.${nodeName};

        user = user;
        sudo = sudo;
        interactiveSudo = interactiveSudo;

        fastConnection = false;

        autoRollback = autoRollback;
        magicRollback = magicRollback;
        activationTimeout = activationTimeout;
        confirmTimeout = confirmTimeout;

        remoteBuild = remoteBuild;
        sshUser = ssh.user;
        sshOpts =
          ssh.opts
          ++ (
            if elem "-p" ssh.opts
            then []
            else ["-p" (toString ssh.port)]
          )
          ++ (
            if elem "-A" ssh.opts
            then []
            else ["-A"]
          );
      };
    });

    checks = mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
  };
in {
  mkNexus = outputs': let
    autogen = mkNexus' <| getAttrOr "nexus" outputs' {};
    outputs = removeAttrs outputs' ["nexus"];
  in
    autogen // outputs; # XXX: TODO: replace this with a deep merge
}
