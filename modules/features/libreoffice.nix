{
  flake.modules.nixos.libreoffice =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.libreoffice ];
    };
}
