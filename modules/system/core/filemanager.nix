{
  flake.modules.nixos.filemanager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      iconTheme = "Papirus-Dark";
      gsettings = lib.getExe' pkgs.glib "gsettings";
    in
    {
      # Matches hyprland fileManager = "nautilus" (Super+E).
      # gvfs covers trash, USB, and network mounts.
      services.gvfs.enable = true;

      # Nautilus looks up sidebar/toolbar symbolic icons (starred,
      # user-trash, ...) from org.gnome.desktop.interface icon-theme.
      # That key is Papirus-Dark; without the theme package, those
      # names miss hicolor and render empty. Adwaita stays as inherit.
      environment.systemPackages = [
        pkgs.nautilus
        pkgs.adwaita-icon-theme
        pkgs.papirus-icon-theme
      ];

      system.activationScripts.applyGtkIconTheme = lib.stringAfter [ "users" ] ''
        iconTheme=${lib.escapeShellArg iconTheme}
        for runtime in /run/user/*; do
          [ -d "$runtime" ] || continue
          uid=''${runtime##*/}
          case "$uid" in
            *[!0-9]* | "") continue ;;
          esac
          if [ -S "$runtime/bus" ]; then
            ${pkgs.util-linux}/bin/runuser -u "#$uid" -- \
              env XDG_RUNTIME_DIR="$runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
              ${gsettings} set org.gnome.desktop.interface icon-theme "$iconTheme" >/dev/null || true
          fi
        done
      '';
    };
}
