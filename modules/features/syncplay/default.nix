{
  flake.modules.nixos.syncplay =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.syncplay ];
    };
}
