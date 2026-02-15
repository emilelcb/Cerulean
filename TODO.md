- [ ] use the Nix module system instead of projectOnto for `cerulean.mkNexus`
- [ ] create an alternative to nixos-install called cerulean-install that
      allows people to easily bootstrap new machines (and host it on dobutterfliescry.net)

- [ ] find an alternative to `nix.settings.trusted-users` probably
- [ ] add the ceru-build user, 
- [ ] add support for github:microvm-nix/microvm.nix
- [ ] add support for sops-nix

- [ ] it would be cool to enable/disable groups and hosts
- [ ] find a standard for how nixpkgs.nix can have a different base per group

- [X] rename nixos-modules/ to nixos/
- [X] ensure all machines are in groups.all by default

## Low Priority
- [ ] rename extraModules to modules?
- [ ] rename specialArgs to args?

- [ ] make an extension to the nix module system (different to mix)
      that allows transformations (ie a stop post config, ie outputs, which
      it then returns instead of config)


```
vms = {
  home-assistant = {
    autostart = true;
    # matches in vms/*
    image = "home-assistant";
    options = {
      mem = 2048;
    };
  };
  equinox = {
    image = "home-assistant";
  };
};
```
