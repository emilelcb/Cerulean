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
  mixture,
  sys,
  lib,
  deploy-rs,
  ...
}: let
  inherit
    (mixture.nodes)
    mapNodes
    ;

  inherit
    (lib)
    nixosSystem
    ;

  mkNexus' = config: rec {
    nixosConfigurations = mapNodes (
      nodeName: node:
        nixosSystem {
          system = node.system;
          modules = node.modules;

          # nix passes these to every single module
          specialArgs =
            node.specialArgs
            // {
              pkgs = sys.pkgsFor node.system;
              upkgs = sys.upkgsFor node.system;
            };
        }
    );

    deploy.nodes = mapNodes (nodeName: node: let
      nixosFor = system: deploy-rs.lib.${system}.activate.nixos;
    in {
      hostname = node.deploy.ssh.host;

      profilesOrder = ["default"]; # profiles priority
      profiles.default = {
        path = nixosFor node.system nixosConfigurations.${nodeName};

        user = node.deploy.user;
        sudo = node.deploy.sudo;
        interactiveSudo = node.deploy.interactiveSudo;

        fastConnection = false;

        autoRollback = node.deploy.autoRollback;
        magicRollback = node.deploy.magicRollback;
        activationTimeout = node.deploy.activationTimeout;
        confirmTimeout = node.deploy.confirmTimeout;

        remoteBuild = node.deploy.remoteBuild;
        sshUser = node.deploy.ssh.user;
        sshOpts =
          node.deploy.ssh.opts
          ++ (
            if builtins.elem "-p" node.deploy.ssh.opts
            then []
            else ["-p" (toString node.deploy.ssh.port)]
          )
          ++ (
            if builtins.elem "-A" node.deploy.ssh.opts
            then []
            else ["-A"]
          );
      };
    });

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
  };
in {
  mkNexus = outputs:
    (mkNexus' outputs.cerulean) // (removeAttrs outputs ["cerulean"]);
}
