{
  inputs,
  ...
}:
{
  flake.modules.nixos.noctalia =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia.nixosModules.default ];

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };
    };
}
