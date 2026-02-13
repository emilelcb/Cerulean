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
  nt,
  lib,
  deploy-rs,
  ...
}: let
  inherit
    (builtins)
    attrNames
    concatLists
    concatStringsSep
    elem
    filter
    getAttr
    isAttrs
    isFunction
    isList
    mapAttrs
    pathExists
    typeOf
    ;

  inherit
    (this)
    mapNodes
    ;

  inherit
    (nt)
    findImport
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
    extraModules = [];
    specialArgs = Terminal {};

    groups = Terminal {};
    nodes = Terminal {};
  };

  ROOT_GROUP_NAME = "all";

  parseGroupDecl = groups: let
    validGroup = g:
      isAttrs g
      || throw ''
        Cerulean Nexus groups must be provided as attribute sets, got "${typeOf g}" instead!
        Ensure all the group definitions are attribute sets under your call to `cerulean.mkNexus`.
        NOTE: Groups can be accessed via `self.groups.PATH.TO.YOUR.GROUP`
      '';
    delegate = parent: gName: g: let
      result =
        (g
          // {
            _name = gName;
            _parent = parent;
          })
        |> mapAttrs (name: value:
          if elem name ["_name" "_parent"]
          # ignore metadata fields
          then value
          else assert validGroup value; (delegate result name value));
    in
      result;
  in
    assert validGroup groups;
      delegate null ROOT_GROUP_NAME groups;

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
        groups = parseGroupDecl base.groups;
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

  getGroupModules = root: nodeName: node:
    assert isList node.groups
    || throw ''
      Cerulean Nexus node "${nodeName}" does not declare group membership as a list, got "${typeOf node.groups}" instead!
      Ensure `nexus.nodes.${nodeName}.groups` is a list under your call to `cerulean.mkNexus`.
    '';
      node.groups
      # ensure all members are actually groups
      |> map (group: let
        got =
          if ! isAttrs group
          then toString group
          else
            group
            |> attrNames
            |> map (name: "${name} = <${typeOf (getAttr name group)}>;")
            |> concatStringsSep " "
            |> (x: "{ ${x} }");
      in
        if group ? _name
        then group
        else
          throw ''
            Cerulean Nexus node "${nodeName}" is a member of an incorrectly structured group.
            Got "${got}" of primitive type "${typeOf group}".
            NOTE: Groups can be accessed via `self.groups.PATH.TO.YOUR.GROUP`
          '')
      # add all inherited groups via _parent
      |> map (let
        delegate = g:
          if g._parent == null
          then [g]
          else [g] ++ delegate (g._parent);
      in
        delegate)
      # flatten recursion result
      |> concatLists
      # find import location
      |> map (group: findImport (root + "/groups/${group._name}"))
      # filter by uniqueness
      |> nt.prim.unique
      # ignore missing groups
      |> filter pathExists;
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
        nodeName: node: let
          nixosDecl = lib.nixosSystem {
            system = node.system;
            specialArgs = let
              specialArgs =
                nexus.specialArgs
                // node.specialArgs
                // {
                  inherit root specialArgs;
                  inherit (node) system;
                  _deploy-rs = deploy-rs;
                };
            in
              specialArgs;
            modules =
              [self.nixosModules.default (findImport (root + "/hosts/${nodeName}"))]
              ++ (getGroupModules root nodeName node)
              ++ node.extraModules
              ++ nexus.extraModules;
          };
        in
          nixosDecl
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
