# Copyright 2026 Emile Clark-Boman
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
  inputs,
  lib,
  ...
}: {
  # nexus
  options = let
    inherit
      (lib)
      mkOption
      types
      ;
  in {
    modules = mkOption {
      type = types.listOf types.path;
    };
    args = mkOption {
      type = types.attrs;
    };

    groups = mkOption {
      type = types.attrs;
    };

    nodes = mkOption {
      type = types.attrsOf (types.submoduleWith ({...}: {
        options = {
          enabled = mkOption {
            type = types.bool;
            default = true;
          };
          system = mkOption {
            type = types.enum inputs.systems;
          };
          groups = mkOption {
            type = types.list;
          };
          modules = mkOption {
            type = types.list;
          };
          args = mkOption {
            type = types.attrs;
          };

          deploy = {
            user = mkOption {
              type = types.str;
            };
            sudoCmd = mkOption {
              type = types.str;
            };
            interactiveSudo = mkOption {
              type = types.bool;
            };

            remoteBuild = mkOption {
              type = types.bool;
            };
            autoRollback = mkOption {
              type = types.bool;
            };
            magicRollback = mkOption {
              type = types.bool;
            };

            activationTimeout = mkOption {
              type = types.int;
            };
            confirmTimeout = mkOption {
              type = types.int;
            };

            ssh = {
              host = mkOption {
                type = types.str;
              };
              user = mkOption {
                type = types.str;
              };
              port = mkOption {
                type = types.int;
              };
              opts = mkOption {
                type = types.listOf types.str;
              };
            };
          };
        };
      }));
    };
  };

  config = {
  };
}
