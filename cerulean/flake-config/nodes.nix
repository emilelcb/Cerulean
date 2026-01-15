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
{nib, ...}: rec {
  # abstract node instance that stores all default values
  templateNode = name: system: let
    Terminal = nib.types.Terminal;

    missing = msg: path:
      Terminal (abort ''
        Each Cerulean Nexus node is required to specify ${msg}!
        Ensure `cerulean.nexus.nodes.${name}.${path}` exists under your call to `cerulean.mkNexus`.
      '');
  in {
    system = missing "its system type" "system"; # intentionally left missing!! (to raise errors)
    modules = missing "its required modules" "modules";
    specialArgs = Terminal {};

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
    if !(builtins.isAttrs nodeAttrs)
    then
      # fail if node is not an attribute set
      abort ''
        Cerulean Nexus nodes must be provided as an attribute set, got "${builtins.typeOf nodeAttrs}" instead!
        Ensure all `cerulean.nexus.nodes.${name}` declarations are attribute sets under your call to `cerulean.mkNexus`.
      ''
    else let
      templateAttrs = templateNode name nodeAttrs.system;
    in
      nib.parse.mergeStructs templateAttrs nodeAttrs;

  mapNodes' = f:
    builtins.mapAttrs
    (nodeName: nodeAttrs: f nodeName (parseNode nodeName nodeAttrs));
}
