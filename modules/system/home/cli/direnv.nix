{
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
      };
    in
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      environment.systemPackages = [ unstable.devenv ];
    };
}
