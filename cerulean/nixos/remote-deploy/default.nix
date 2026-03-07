{
  config,
  node,
  lib,
  pkgs,
  hostname,
  ...
}: let
  user = node.deploy.ssh.user;
  cfg = config.users.users.${user};

  DEFAULT_USER = "cerubld";

  isStandardDeployUser = user == DEFAULT_USER;
in {
  assertions = [
    {
      assertion = builtins.length node.deploy.ssh.publicKeys != 0;
      message = ''
        The Cerulean deployment user `${user}` for node `${hostname}` must have at least
        one publicKey authorized for ssh deployment! Try setting `nodes.nodes.<name>.deploy.ssh.publicKeys = [ ... ]` <3
      '';
    }
    {
      assertion = cfg.isSystemUser && !cfg.isNormalUser;
      message = ''
        The Cerulean deployment user `${user}` for node `${hostname}` has been configured incorrectly.
        Ensure `users.users.${user}.isSystemUser == true` and `users.users.${user}.isNormalUser == false`.
      '';
    }
  ];

  warnings = lib.optional (node.deploy.warnNonstandardDeployUser && !isStandardDeployUser) ''
    The Cerulean deplyment user `${user}` for node `${hostname}` has been overriden.
    It is recommended to leave this user as `${DEFAULT_USER}` unless you TRULY understand what you are doing!
    This message can be disabled by setting `<node>.deploy.warnNonstandardBuildUser = false`.
  '';

  # prefer sudo-rs over sudo
  security.sudo-rs = {
    enable = true;
    wheelNeedsPassword = true;

    # allow the build user to run nix commands
    extraRules = [
      {
        users = [user];
        runAs = "${node.deploy.user}:ALL";
        commands = [
          "${pkgs.nix}/bin/nix"
        ];
      }
    ];
  };

  # ensure deployment user has SSH permissions
  services.openssh.settings.AllowUsers = [user];

  users = lib.mkIf isStandardDeployUser {
    groups.${user} = {};

    users.${user} = {
      enable = true;
      isSystemUser = true;
      group = user;
      description = "Cerulean's user for building and remote deployment.";

      shell = pkgs.bash;
      openssh.authorizedKeys.keys = node.deploy.ssh.publicKeys;
    };
  };
}
