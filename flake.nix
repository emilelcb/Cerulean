{
  description = "Your Nix Cloud Simplified";

  inputs = let
    follows = following: {
      inputs = builtins.listToAttrs (builtins.map (x: {
          name = x;
          value = {follows = x;};
        })
        following);
    };
  in {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nib = {
      url = "github:emileclarkb/nib";
      inputs = follows ["systems"];
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
    # overlays.default = final: prev: {
    # };

    # checks = self.packages;
    # packages =
    #   forAllSystems (system: pkgs: rec {
    #   });

    mkNexusConfig = config: let
      mapNodes = f: lib.mapAttrs f config.nexus.nodes;
    in rec {
      nixosConfigurations = mapNodes (
        name: node:
          lib.nixosSystem {
            system = node.system;
            modules = node.modules;
          }
      );

      deploy.nodes = mapNodes (name: node: {
        hostname = name;
        profiles.system = {
          user = "root";
          path = let
            system = node.system;
          in
            deploy-rs.lib.${system}.activate.nixos nixosConfigurations.${system};
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
