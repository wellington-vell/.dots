{
  flake.modules.nixos.base =
    { lib, config, ... }:
    let
      monitorType = lib.types.submodule {
        options = {
          output = lib.mkOption {
            type = lib.types.str;
            description = "DRM connector name (e.g. HDMI-A-2).";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "preferred";
            description = ''
              Resolution for SDDM xrandr, or "preferred" for Hyprland auto mode.
              When not "preferred", Hyprland uses the same string as mode.
            '';
          };
          position = lib.mkOption {
            type = lib.types.str;
            default = "0x0";
            description = "Monitor position (e.g. 1920x0).";
          };
          scale = lib.mkOption {
            type = lib.types.str;
            default = "auto";
            description = "Hyprland scale factor (e.g. auto, 1).";
          };
          primary = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Mark as primary for SDDM xrandr.";
          };
          defaultWorkspace = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            description = "Default workspace number for this monitor, if any.";
          };
        };
      };
    in
    {
      options.host = {
        monitors = lib.mkOption {
          type = lib.types.listOf monitorType;
          default = [ ];
          description = "Per-host monitor layout for Hyprland and SDDM. Empty = auto.";
        };

        locale = lib.mkOption {
          type = lib.types.str;
          default = "en_US.UTF-8";
          description = "System default locale (i18n.defaultLocale).";
        };

        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "America/Sao_Paulo";
          description = "System time zone (time.timeZone).";
        };

        apps = {
          terminal = lib.mkOption {
            type = lib.types.str;
            default = "ghostty";
            description = "Default terminal command for Hyprland binds.";
          };
          fileManager = lib.mkOption {
            type = lib.types.str;
            default = "nautilus";
            description = "Default file manager for Hyprland binds.";
          };
          browser = lib.mkOption {
            type = lib.types.str;
            default = "zen-beta";
            description = "Default browser for Hyprland binds.";
          };
          menu = lib.mkOption {
            type = lib.types.str;
            default = "hyprlauncher";
            description = "Default app launcher for Hyprland binds.";
          };
        };
      };

      config = {
        i18n.defaultLocale = config.host.locale;
        time.timeZone = config.host.timeZone;
      };
    };
}
