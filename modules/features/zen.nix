{
  inputs,
  ...
}:
{
  flake.modules.nixos.zen =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
