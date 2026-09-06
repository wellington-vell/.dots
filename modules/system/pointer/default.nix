{
  flake.modules.nixos.pointer =
    { pkgs, lib, config, ... }:
    let
      cursorPackage = pkgs.bibata-cursors;
      theme = "Bibata-Modern-Classic";
      size = 24;
      hyprctl = lib.getExe' pkgs.hyprland "hyprctl";
      gsettings = lib.getExe' pkgs.glib "gsettings";

      defaultIndexTheme = pkgs.writeText "cursor-default-index.theme" ''
        [Icon Theme]
        Name=Default
        Comment=Default Cursor Theme
        Inherits=${theme}
      '';

      defaultCursorTheme = pkgs.runCommand "pointer-default-cursor-theme" { } ''
        mkdir -p $out/share/icons/default
        ln -s ${defaultIndexTheme} $out/share/icons/default/index.theme
      '';

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      environment.systemPackages = [ cursorPackage ];
      xdg.icons.fallbackCursorThemes = [ theme ];
      programs.steam.extraPackages = [
        cursorPackage
        defaultCursorTheme
      ];

      environment.sessionVariables = {
        XCURSOR_THEME = theme;
        XCURSOR_SIZE = toString size;
        HYPRCURSOR_SIZE = toString size;
      };

      # Apply on switch: per-user default theme (first on XCURSOR_PATH) + live session.
      system.activationScripts.applyPointer = lib.stringAfter [ "users" ] ''
        theme=${lib.escapeShellArg theme}
        size=${toString size}

        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.local/share/icons/default"
          ln -sfn ${defaultIndexTheme} "$home/.local/share/icons/default/index.theme"
          chown -R --reference="$home" "$home/.local/share/icons" 2>/dev/null || true
        done

        for runtime in /run/user/*; do
          [ -d "$runtime" ] || continue
          uid=''${runtime##*/}
          case "$uid" in
            *[!0-9]* | "") continue ;;
          esac

          if [ -d "$runtime/hypr" ]; then
            for instance in "$runtime"/hypr/*; do
              [ -d "$instance" ] || continue
              sig=''${instance##*/}
              ${pkgs.util-linux}/bin/runuser -u "#$uid" -- \
                env XDG_RUNTIME_DIR="$runtime" HYPRLAND_INSTANCE_SIGNATURE="$sig" \
                ${hyprctl} setcursor "$theme" "$size" >/dev/null || true
            done
          fi

          if [ -S "$runtime/bus" ]; then
            ${pkgs.util-linux}/bin/runuser -u "#$uid" -- \
              env XDG_RUNTIME_DIR="$runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
              ${gsettings} set org.gnome.desktop.interface cursor-theme "$theme" >/dev/null || true
            ${pkgs.util-linux}/bin/runuser -u "#$uid" -- \
              env XDG_RUNTIME_DIR="$runtime" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
              ${gsettings} set org.gnome.desktop.interface cursor-size "$size" >/dev/null || true
          fi
        done
      '';
    };
}
