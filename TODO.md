## Next
- [ ] add `options.experimental` for snowflake
- [ ] add `legacyImports` support

- [ ] support hs system per dir, ie hosts/<name>/overlays or hosts/<name>/nixpkgs.nix

## Queued
- [ ] per node home configuration is a lil jank rn

- [ ] deploy port should default to the first port given to `services.openssh`

- [ ] create an alternative to nixos-install called cerulean-install that
      allows people to easily bootstrap new machines (and host it on dobutterfliescry.net)

- [ ] find an alternative to `nix.settings.trusted-users` probably
- [ ] add the ceru-build user, 
- [ ] add support for github:microvm-nix/microvm.nix
- [ ] add support for sops-nix

- [ ] it would be cool to enable/disable groups and hosts
- [ ] find a standard for how nixpkgs.nix can have a different base per group

- [ ] go through all flake inputs (recursively) and ENSURE we remove all duplicates by using follows!!

- [ ] allow multiple privesc methods, the standard is pam_ssh_agent_auth

## Low Priority
- [ ] make an extension to the nix module system (different to mix)
      that allows transformations (ie a stop post config, ie outputs, which
      it then returns instead of config)
- [ ] support `legacyImports` (?)

- [ ] patch microvm so that acpi=off https://github.com/microvm-nix/microvm.nix/commit/b59a26962bb324cc0a134756a323f3e164409b72
      cause otherwise 2GB causes a failure

- [ ] write the cerulean cli


```nix
# REF: foxora
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
