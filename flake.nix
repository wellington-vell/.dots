{
  description = "NixOS dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  # Cursor lags in the SCM commit box on 3.5.x; fix landed in 3.8+.
  # Keep system on 26.05, pull a newer code-cursor from unstable.
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.import-tree.url = "github:denful/import-tree";
  inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.claude-desktop = {
    url = "github:aaddrick/claude-desktop-debian";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.phonebridge = {
    url = "github:wellington-vell/phonebridge";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # Android dev shell of the Phonebridge app (app/flake.nix). No `follows`:
  # keeping its own nixpkgs pin makes the store paths identical to
  # `nix develop ./app`, so the SDK/NDK rooted here are the ones builds use.
  inputs.phonebridge-app.url = "github:wellington-vell/phonebridge?dir=app";
  inputs.noctalia.url = "github:noctalia-dev/noctalia/cachix";
  # Source for the patched screen_recorder plugin (modules/system/home/noctalia).
  inputs.noctalia-plugins = {
    url = "github:noctalia-dev/official-plugins";
    flake = false;
  };
  inputs.identity = {
    url = "path:/home/well/.secrets";
    flake = false;
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        (inputs.import-tree ./modules)
      ];
    };
}
