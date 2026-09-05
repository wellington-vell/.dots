{
  flake.modules.nixos.editors =
    { pkgs, ... }:
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      environment.systemPackages = with pkgs; [
        vscode
        code-cursor
      ];
    };
}
