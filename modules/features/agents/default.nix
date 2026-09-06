{
  inputs,
  ...
}:
{
  flake.modules.nixos.agents =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
      };
    in
    {
      environment.systemPackages = [
        unstable.opencode
        pkgs.pi-coding-agent
      ];
    };
}
