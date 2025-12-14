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
      url = "github:emilelcb/nib";
      inputs.systems.follows = "systems";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nib,
    deploy-rs,
    ...
  } @ inputs:
    with builtins;
    with nib.types; let
      lib = nixpkgs.lib;

      sys = with nib;
        mkUSys {
          pkgs = withPkgs nixpkgs {
            config.allowUnfree = false;
            overlays = attrValues self.overlays;
          };
          upkgs = withPkgs nixpkgs-unstable {
            config.allowUnfree = false;
          };
        };
    in rec {
      overlays = [
        # deploy-rs is built from the flake input, not from nixpkgs!
        # To take advantage of the nixpkgs binary cache,
        # the deploy-rs package can be overwritten:
        deploy-rs.overlays.default
        (self: super: {
          deploy-rs = {
            inherit (super) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];

      mkNexusConfig = config: let
        # abstract node instance that stores all default values
        templateNode = name: system: let
          missing = msg: path:
            Terminal (abort ''
              Each Cerulean Nexus node is required to specify ${msg}!
              Ensure `cerulean.nexus.nodes.${name}.${path}` exists under your call to `cerulean.mkNexus`.
            '');
        in {
          system = missing "its system type" "system"; # intentionally left missing!! (to raise errors)
          modules = missing "its required modules" "modules";
          specialArgs = Terminal {
            inherit inputs;
            pkgs = sys.pkgsFor system;
            upkgs = sys.upkgsFor system;
          };

          deploy = {
            user = "root";
            sudo = "sudo -u";
            interactiveSudo = false;

            remoteBuild = false; # prefer local builds for remote deploys

            autoRollback = true; # reactivate previous profile if activation fails
            magicRollback = true;

            activationTimeout = 500; # timeout in seconds for profile activation
            confirmTimeout = 30; # timeout in seconds for profile activation confirmation

            ssh = {
              host = missing "an SSH hostname (domain name or ip address) for deployment" "deploy.ssh.host";
              user = missing "an SSH username for deployment" "deploy.ssh.user";
              port = 22;
              opts = [];
            };
          };
        };

        parseNode = name: nodeAttrs:
          if !(isAttrs nodeAttrs)
          then
            # fail if node is not an attribute set
            abort ''
              Cerulean Nexus nodes must be provided as an attribute set, got "${typeOf nodeAttrs}" instead!
              Ensure all `cerulean.nexus.nodes.${name}` declarations are attribute sets under your call to `cerulean.mkNexus`.
            ''
          # TODO: nodeAttrs.system won't display any nice error messages!!
          # TODO: will mergeTypedStruct give nice error messages? or should I use mergeStructErr directly?
          else let
            templateAttrs = templateNode name nodeAttrs.system;
            S = nib.parse.parseStructFor templateAttrs nodeAttrs;
          in
            unwrapRes (_:
              abort ''
                Cerulean failed to parse `cerulean.nexus.nodes.${name}`!
                mergeStruct should never return `result.Err`... How are you here?!?
              '')
            S;

        # TODO: mapNodes = f: mapAttrs (name: nodeAttrs: f name (parseNode name nodeAttrs)) config.nexus.nodes
        mapNodes = f: mapAttrs f (mapAttrs parseNode config.nexus.nodes);
      in rec {
        nixosConfigurations = mapNodes (
          _: node:
            lib.nixosSystem {
              system = node.system;
              modules = node.modules;

              # nix passes these to every single module
              specialArgs = {} // node.modules.specialArgs;
            }
        );

        deploy.nodes = mapNodes (_: node: {
          hostname = node.deploy.ssh.host;

          profilesOrder = ["default"]; # profiles priority
          profiles.default = {
            path = deploy-rs.lib.${node.system}.activate.nixos nixosConfigurations.${node.system};

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
                if elem "-p" node.deploy.ssh.opts
                then []
                else ["-p" (toString node.deploy.ssh.port)]
              );
          };
        });

        checks = mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
      };

      mkNexus = outputs: let
        config = outputs.cerulean;
      in
        (mkNexusConfig config) // (removeAttrs outputs ["cerulean"]);
    };
}
