{
  flake.modules.nixos.vscode =
    { pkgs, ... }:
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = [ pkgs.vscode ];
    };
}
