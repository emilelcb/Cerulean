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
  lib,
  deploy-rs,
  ...
}: let
  inherit
    (this)
    mapNodes
    ;

  mkNexus' = config: rec {
    nixosConfigurations = mapNodes config.nexus.nodes (
      nodeName: node:
        lib.nixosSystem {
          system = node.system;
          modules = [./hosts/${nodeName}] ++ node.extraModules;

          # nix passes these to every single module
          specialArgs =
            node.specialArgs
            // {
              pkgs = sys.pkgsFor node.system;
              upkgs = sys.upkgsFor node.system;
            };
        }
    );

    deploy.nodes = mapNodes config.nexus.nodes (nodeName: node: let
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
            if builtins.elem "-p" ssh.opts
            then []
            else ["-p" (toString ssh.port)]
          )
          ++ (
            if builtins.elem "-A" ssh.opts
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
