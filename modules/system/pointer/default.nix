{
  flake.modules.nixos.pointer =
    { pkgs, ... }:
    {
      # Omarchy ships yaru-icon-theme; match with Yaru cursors at size 24
      environment.systemPackages = [ pkgs.yaru-theme ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Yaru";
        XCURSOR_SIZE = "24";
        HYPRCURSOR_SIZE = "24";
      };
    };
}
