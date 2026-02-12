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
  self,
  this,
  nixpkgs,
  nixpkgs-unstable,
  nt,
  lib,
  deploy-rs,
  ...
}: let
  inherit
    (builtins)
    attrNames
    concatStringsSep
    elem
    getAttr
    isAttrs
    isFunction
    mapAttrs
    pathExists
    typeOf
    ;

  inherit
    (this)
    mapNodes
    ;

  templateNexus = let
    inherit
      (nt.naive.terminal)
      Terminal
      ;

    missing = msg: path:
      Terminal (abort ''
        Each Cerulean Nexus node is required to specify ${msg}!
        Ensure `nexus.${path}` exists under your call to `cerulean.mkNexus`.
      '');
  in {
    groups = Terminal {};
    overlays = [];
    nodes = Terminal {};
  };

  parseGroups = groups: let
    validGroup = g:
      isAttrs g
      || throw ''
        Cerulean Nexus groups must be provided as attribute sets, got "${typeOf g}" instead!
        Ensure all the `groups` definitions are attribute sets under your call to `cerulean.mkNexus`.
      '';
    delegate = parent: g:
      g
      |> mapAttrs (name: value:
        assert validGroup value;
          (delegate g value)
          // {
            _name = name;
            _parent = parent;
          });
  in
    assert validGroup groups;
      delegate null groups;

  parseNexus = nexus:
    assert isAttrs nexus
    || abort ''
      Cerulean Nexus config must be provided as an attribute set, got "${typeOf nexus}" instead!
      Ensure all the `nexus` declaration is an attribute set under your call to `cerulean.mkNexus`.
    ''; let
      base = nt.projectOnto templateNexus nexus;
    in
      # XXX: TODO: create a different version of nt.projectOnto that can actually
      # XXX: TODO: handle applying a transformation to the result of each datapoint
      base
      // {
        groups = parseGroups base.groups;
      };

  parseDecl = outputsBuilder: let
    decl = (
      if isFunction outputsBuilder
      then outputsBuilder final # provide `self`
      else
        assert (isAttrs outputsBuilder)
        || abort ''
          Cerulean declaration must be provided as an attribute set, got "${typeOf outputsBuilder}" instead!
          Ensure your declaration is an attribute set or function under your call to `cerulean.mkNexus`.
        ''; outputsBuilder
    );

    final =
      decl
      // {
        nexus = parseNexus (decl.nexus or {});
      };
  in
    final;

  # XXX: TODO: create a function in NixTypes that handles this instead
  findImport = path:
    if pathExists path
    then path
    else path + ".nix";
in {
  mkNexus = root: outputsBuilder: let
    decl = parseDecl outputsBuilder;

    inherit
      (decl)
      nexus
      ;
    customOutputs = removeAttrs decl ["nexus"];

    outputs = rec {
      nixosConfigurations = mapNodes nexus.nodes (
        nodeName: node:
          lib.nixosSystem {
            system = node.system;
            modules = let
              host = findImport (root + "/hosts/${nodeName}");
              # XXX: TODO: don't use a naive type for this (ie _name property)
              # XXX: TODO: i really need NixTypes to be stable and use that instead
              groups =
                node.groups
                |> map (group:
                  assert group ? _name
                  || throw (let
                    got =
                      if ! isAttrs group
                      then toString group
                      else
                        group
                        |> attrNames
                        |> map (name: "${name} = <${typeOf (getAttr name group)}>;")
                        |> concatStringsSep " "
                        |> (x: "{ ${x} }");
                  in ''
                    Cerulean Nexus node "${nodeName}" is a member of a nonexistent group.
                    Got "${got}" of primitive type "${typeOf group}".
                    NOTE: Groups can be accessed via `self.groups.PATH.TO.YOUR.GROUP`
                  '');
                    findImport (root + "/groups/${group._name}"));
            in
              [../nixos-module host] ++ groups ++ node.extraModules;

            # nix passes these to every single module
            specialArgs = let
              pkgConfig =
                {
                  inherit (node) system;
                  # XXX: WARNING: TODO: i've stopped caring
                  # XXX: WARNING: TODO: just figure out a better solution to pkgConfig
                  config.allowUnfree = true;
                  overlays = self.overlays ++ nexus.overlays ++ node.overlays;
                }
                // node.extraPkgConfig;
            in
              node.specialArgs
              // {
                pkgs = import nixpkgs pkgConfig;
                upkgs = import nixpkgs-unstable pkgConfig;
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
  in
    outputs // customOutputs;
}
