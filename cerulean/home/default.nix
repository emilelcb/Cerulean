# NOTE: you can access the system configuration via the `osConfig` arg
{
  username,
  lib,
  ...
}: {
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
