{
  flake.modules.nixos.pointer =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.yaru-theme ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Yaru";
        XCURSOR_SIZE = "24";
        HYPRCURSOR_SIZE = "24";
      };
    };
}
