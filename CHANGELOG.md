# Changelog

## v0.2.0-alpha
Initial "stable" release. Cerulean is currently usable and supports:
1. local & remote deployment configuration
2. nixos/homemanager module-level support for any number of nixpkg branches
3. use of the [nix-systems standard](https://github.com/nix-systems/nix-systems), the introduction of the `snow/flake` standard, and the introduction of the `nixpkgs.nix` standard module.
4. hierarchical groups for NixOS hosts via `snow.nix`

This is still a alpha-build of Cerulean. Everything will break in the future as I change the internals a bunch. I'll aim to write documentation in future cause currently there's no guide.

## v0.2.1-alpha
Minor patches
- cerulean no longer has a `inputs.nixpkgs-unstable` (the `nixpkgs.nix` is the new alternative)
- `home-manager.nixosModules.default` and `microvm.nixosModules.microvm` are added as default modules
- fixed `groups.all` not being added to nodes with `groups = []`

## v0.2.2-alpha
Minor patches
- fixed `nexus.groups.all` not added to empty `nexus.nodes.*.groups` declarations
- fixed bad propagation of inputs
- forced system architecture to be specified per node
- cerulean no longer depends on `nixpkgs`,  `base` package set should be set instead
- rename `extraModules` -> `modules`
- rename `specialArgs` -> `args`
