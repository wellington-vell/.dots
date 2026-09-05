{
  flake.modules.nixos.base = {
    programs.hyprland.enable = true;

    services.xserver.enable = true;
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = false;
      };
      defaultSession = "hyprland";
    };

    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    environment.etc."hypr/hyprland.lua".source = ../config/hypr/hyprland.lua;
    environment.etc."hypr/setup-audio.sh".source = ../config/hypr/setup-audio.sh;

    system.activationScripts.hyprConfig = ''
      USER_HOME=$(getent passwd well | cut -d: -f6)
      mkdir -p "$USER_HOME/.config/hypr"
      cp -f /etc/hypr/hyprland.lua "$USER_HOME/.config/hypr/hyprland.lua"
      cp -f /etc/hypr/setup-audio.sh "$USER_HOME/.config/hypr/setup-audio.sh"
    '';
  };
}