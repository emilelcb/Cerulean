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
  username,
  lib,
  ...
}: {
  # NOTE: you can access the system configuration via the `osConfig` arg

  # WARNING: required for home-manager to work
  programs.home-manager.enable = true; # user must apply lib.mkForce
  # Nicely reload systemd units when changing configs
  systemd.user.startServices = lib.mkDefault "sd-switch";

  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault "/home/${username}";

    sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = lib.mkDefault 1;
    };
  };
}
