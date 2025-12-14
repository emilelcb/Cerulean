{
  description = "Your Nix Cloud Simplified";

  inputs = {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nib = {
      url = "github:emilelcb/nib";
      inputs.systems.follows = "systems";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nib,
    deploy-rs,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

    sys = with nib;
      mkUSys {
        pkgs = withPkgs nixpkgs {
          config.allowUnfree = false;
          overlays = builtins.attrValues self.overlays;
        };
        upkgs = withPkgs nixpkgs-unstable {
          config.allowUnfree = false;
        };
      };
  in rec {
    overlays = [
      # deploy-rs is built from the flake input, not from nixpkgs!
      # To take advantage of the nixpkgs binary cache,
      # the deploy-rs package can be overwritten:
      deploy-rs.overlays.default
      (self: super: {
        deploy-rs = {
          inherit (super) deploy-rs;
          lib = super.deploy-rs.lib;
        };
      })
    ];

    mkNexusConfig = config: let
      # abstract node instance that stores all default values
      templateNode = name: system: let
        missing = msg: path:
          builtins.abort ''
            Each Cerulean Nexus node is required to specify ${msg}!
            Ensure `cerulean.nexus.nodes.${name}.${path}` exists under your call to `cerulean.mkNexus`.
          '';
      in {
        system = missing "its system type" "system"; # intentionally left missing!! (to raise errors)
        modules = missing "its required modules" "modules";
        specialArgs = {
          inherit inputs;
          pkgs = sys.pkgsFor system;
          upkgs = sys.upkgsFor system;
        };

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
          builtins.abort ''
            Cerulean Nexus nodes must be provided as an attribute set, got "${builtins.typeOf nodeAttrs}" instead!
            Ensure all `cerulean.nexus.nodes.${name}` declarations are attribute sets under your call to `cerulean.mkNexus`.
          ''
        # TODO: nodeAttrs.system won't display any nice error messages!!
        # TODO: will mergeTypedStruct give nice error messages? or should I use mergeStructErr directly?
        else let
          templateAttrs = templateNode name nodeAttrs.system;
          r = nib.parse.mergeStruct templateAttrs nodeAttrs;
        in
          nib.types.unwrapRes (_:
            builtins.abort ''
              Cerulean failed to parse `cerulean.nexus.nodes.${name}`!
              mergeStruct should never return `result.Err`... How are you here?!?
            '')
          r;

      # TODO: mapNodes = f: builtins.mapAttrs (name: nodeAttrs: f name (parseNode name nodeAttrs)) config.nexus.nodes
      mapNodes = f: builtins.mapAttrs f (builtins.mapAttrs parseNode config.nexus.nodes);
    in rec {
      nixosConfigurations = mapNodes (
        _: node:
          lib.nixosSystem {
            system = node.system;
            modules = node.modules;

            # nix passes these to every single module
            specialArgs = {} // node.modules.specialArgs;
          }
      );

      deploy.nodes = mapNodes (_: node: {
        hostname = node.deploy.ssh.host;

        profilesOrder = ["default"]; # profiles priority
        profiles.default = {
          path = deploy-rs.lib.${node.system}.activate.nixos nixosConfigurations.${node.system};

          user = node.deploy.user;
          sudo = node.deploy.sudo;
          interactiveSudo = node.deploy.interactiveSudo;

          fastConnection = false;

          autoRollback = node.deploy.autoRollback;
          magicRollback = node.deploy.magicRollback;
          activationTimeout = node.deploy.activationTimeout;
          confirmTimeout = node.deploy.confirmTimeout;

          remoteBuild = node.deploy.remoteBuild;
          sshUser = node.deploy.ssh.user;
          sshOpts =
            node.deploy.ssh.opts
            ++ (
              if builtins.elem "-p" node.deploy.ssh.opts
              then []
              else ["-p" (builtins.toString node.deploy.ssh.port)]
            );
        };
      });

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
    };

    mkNexus = outputs: let
      config = outputs.cerulean;
    in
      (mkNexusConfig config) // (builtins.removeAttrs outputs ["cerulean"]);
  };
}
