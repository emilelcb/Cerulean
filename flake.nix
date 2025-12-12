{
  description = "Your Nix Cloud Simplified";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    self,
    systems,
    nixpkgs,
    ...
  }: let
    defaultSystems = ["aarch64-darwin" "aarch64-linux" "i686-linux" "x86_64-darwin" "x86_64-linux"];

    forAllSystems = f:
      nixpkgs.lib.genAttrs defaultSystems (system:
        f system (import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        }));
  in {
    overlays.default = final: prev: {
    };

    checks = self.packages;
    packages =
      forAllSystems (system: pkgs: rec {
      });
  };
}
