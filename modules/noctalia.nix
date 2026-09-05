{
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia.nixosModules.default ];

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };
    };
}