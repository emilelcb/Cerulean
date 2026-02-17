![enbyware](https://pride-badges.pony.workers.dev/static/v1?label=enbyware&labelColor=%23555&stripeWidth=8&stripeColors=FCF434%2CFFFFFF%2C9C59D1%2C2C2C2C)
![repo size](https://img.shields.io/github/repo-size/cry128/cerulean)

>[!WARNING]
> ✨ **Under Construction** ✨
> Cerulean has lived rent free in my head for the last 12 months.
> I'm developing this project for personal use and especially
> for use at my workplace. **Be not afraid!** It's only a matter
> of time until Cerulean is ready for use!

# 🌌 🚀 Cerulean Nexus
The culmination of 2 years designing better Nix flakes. Cerulean removes the boilerplate of managing
NixOS infrastructure by declaring each machine as a **node** and their relationships as *"Nexus Networks"*,
virtual networks of servers that Cerulean can manage. Each Nexus is **very powerful**. Allowing for simple
distributed computing, automatic construction of VPNs, DNS for local hostnames, and that's just scratching the surface...

- Is your node a VPS? Set `deploy.ssh.host = "example.com"` and Cerulean will configure custom build users,
  ssh deployment via custom PAM modules, etc etc
- Is your node a VM? Set `vms = [ nodes.VM_NODE ]` on your host node, and Cerulean will configure
  all the bridging, NAT, and other networking you so desire!

## 🩷💜 Motivation
Nix is intended as a non-restrictive & unopinionated system, which is amazing, but it also means
every user develops their own standards to simplify their config. Cerulean however is very much
opinionated and contains all the standards I personally believe should be sane defaults for every NixOS machine.

> Flakes are not designed for NixOS, they're designed for Nix, and that's an important distinction.

Flakes and NixOS don't offer anything to simplify managing interconnected nodes of machines.
But this ends with *extremely messy configs* with **a lot of footguns**. You shouldn't have to spend
days reading about networking and learning to work with other peoples' modules.

Finally, the Nix module system assumes you only use one channel of `github:NixOS/nixpkgs` but this
just isn't realistic. Most people have both `inputs.nixpkgs` and `inputs.nixpkgs-unstable` defined.
So cerulean declares the `nixpkgs.channels.*` option so you don't have to import your channels
manually!

## 💙 Same Colour, More Control
>[!NOTE]
> This section is *mostly* for the business minded people.

Cerulean is what you wish Azure could be. Providing an expansive collection of microservices, pre-configured systems,
and entirely self-hosted! Cerulean is built using NixOS as a foundation so you know it's never going to break randomly.
NixOS backing makes Cerulean **extremely scalable**! Just rent a new VPS and Cerulean will build an ISO of your configuration.

No stress, no hassle!
Say goodbye to Azure! And say goodbye to Kubernetes! You're taking life into your own hands 💙

