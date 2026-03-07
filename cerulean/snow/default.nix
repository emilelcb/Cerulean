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
  this,
  self,
  inputs,
  systems,
  nt,
  mix,
  ...
} @ args: let
  inherit
    (builtins)
    all
    attrNames
    elem
    mapAttrs
    warn
    ;

  inherit (inputs.nixpkgs) lib;

  inherit (nt) findImport;
in
  mix.newMixture args (mixture: let
    inherit (mixture) mapNodes;
  in {
    includes.private = [
      ./lib/nodes.nix
    ];

    inherit findImport;

    # snow.flake
    flake = flakeInputs: root: let
      module = lib.evalModules {
        class = "snowflake";
        # TODO: abort if inputs contains reserved names
        specialArgs =
          flakeInputs
          // {
            inherit root;
            inherit systems;
            inherit (this) snow; # please don't be infinite recursion...
            inputs = flakeInputs;
          };

        modules = [
          ./module.nix
        ];
      };

      nodes = module.config.nodes;
    in rec {
      nixosConfigurations = mapNodes nodes (
        {
          base,
          lib,
          name,
          node,
          groupModules,
          ...
        }: let
          homeManager =
            if node.homeManager != null
            then node.homeManager
            else if nodes.homeManager != null
            then nodes.homeManager
            else
              warn ''
                [snowflake] Neither `nodes.homeManager` nor `nodes.nodes.${name}.homeManager` were specified!
                [snowflake] home-manager will NOT be used! User configuration will be ignored!
              ''
              null;

          userArgs = nodes.args // node.args;
          ceruleanArgs = {
            inherit systems root base;
            inherit (node) system;
            inherit (this) snow;

            _cerulean = {
              inherit inputs userArgs ceruleanArgs homeManager;
              specialArgs = userArgs // ceruleanArgs;
            };
          };
          specialArgs = assert (userArgs
            |> attrNames
            |> all (argName:
              ! ceruleanArgs ? argName
              || abort ''
                `specialArgs` are like super important to Cerulean my love... </3
                But `args.${argName}` is a reserved argument name :(
              ''));
            ceruleanArgs._cerulean.specialArgs;
        in
          lib.nixosSystem {
            inherit (node) system;
            inherit specialArgs;
            modules =
              [
                self.nixosModules.default
                (findImport /${root}/hosts/${name})
              ]
              ++ (groupModules root)
              ++ node.modules
              ++ nodes.modules;
          }
      );

      deploy.nodes = mapNodes nodes ({
        name,
        node,
        ...
      }: let
        inherit
          (node.deploy)
          ssh
          user
          sudoCmd
          interactiveSudo
          remoteBuild
          rollback
          autoRollback
          magicRollback
          activationTimeout
          confirmTimeout
          ;

        nixosFor = system: inputs.deploy-rs.lib.${system}.activate.nixos;
      in {
        hostname = ssh.host;

        profilesOrder = ["default"]; # profiles priority
        profiles.default = {
          path = nixosFor node.system nixosConfigurations.${name};

          user = user;
          sudo = sudoCmd;
          interactiveSudo = interactiveSudo;

          fastConnection = false;

          autoRollback = autoRollback -> rollback;
          magicRollback = magicRollback -> rollback;
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

      checks =
        inputs.deploy-rs.lib
        |> mapAttrs (system: deployLib:
          deployLib.deployChecks deploy);
    };
  })
