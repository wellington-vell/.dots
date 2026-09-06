{
  flake.modules.nixos.portal =
    { pkgs, ... }:
    {
      # Browser / Electron screen sharing (Hyprland portal is pulled in by
      # programs.hyprland; keep GTK portal for file/app choosers).
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = [
          "hyprland"
          "gtk"
        ];
      };
    };
}
