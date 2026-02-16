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
{nt, ...}: let
  inherit
    (builtins)
    isAttrs
    mapAttrs
    typeOf
    ;
in rec {
  # abstract node instance that stores all default values
  templateNode = name: system: let
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
    enabled = true;
    system = missing "its system architecture" "system";
    groups = [];
    extraModules = [];
    specialArgs = Terminal {};

    base = null;

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
        host = name;
        user = "ceru-build"; # ceru-build is the default connection user
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
    else let
      templateAttrs = templateNode name nodeAttrs.system;
    in
      nt.projectOnto templateAttrs nodeAttrs;

  mapNodes = nexus: f:
    nexus.nodes
    |> mapAttrs (nodeName: nodeAttrs: let
      node = parseNode nodeName nodeAttrs;

      # use per-node base or default to nexus base
      base =
        if node.base != null
        then node.base
        else if nexus.base != null
        then nexus.base
        else
          abort ''
            Cerulean cannot construct nexus node "${nodeName}" without a base package source.
            Ensure `nexus.nodes.*.base` or `nexus.base` is a flake reference to the github:NixOS/nixpkgs repository.
          '';
    in
      f {
        inherit nodeName node;
        lib = base.lib;
      });
}
