{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      environment.systemPackages = [ pkgs.devenv ];
    };
}
