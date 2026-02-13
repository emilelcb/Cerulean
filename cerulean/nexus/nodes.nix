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
  in {
    system = "x86_64-linux"; # sane default (i hope...)
    groups = [];
    extraModules = [];
    specialArgs = Terminal {};
    overlays = [];

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

  mapNodes = nodes: f:
    nodes
    |> mapAttrs (nodeName: nodeAttrs: f nodeName (parseNode nodeName nodeAttrs));
}
