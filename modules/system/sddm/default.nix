{
  flake.modules.nixos.sddm =
    { pkgs, ... }:
    let
      sddm-astronaut = pkgs.sddm-astronaut.override {
        embeddedTheme = "black_hole";
        # Available: astronaut, black_hole, cyberpunk, hyprland_kath,
        # jake_the_dog, japanese_aesthetic, pixel_sakura,
        # pixel_sakura_static, post-apocalyptic_hacker, purple_leaves
        # Optional inline overrides (merged via themeConfig):
        # themeConfig = {
        #   Background = "Backgrounds/black_hole.png";
        #   Blur = "2.0";
        #   FormPosition = "center";
        # };
      };
    in
    {
      environment.systemPackages = [ sddm-astronaut ];

      services.displayManager = {
        sddm = {
          enable = true;
          package = pkgs.kdePackages.sddm;
          theme = "sddm-astronaut-theme";
          # Switch to X11 greeter so xrandr setupScript can force primary.
          # Weston (wayland greeter) ignores xrandr and picks the first DRM
          # connector — on this rig that's DVI-D-2 (secondary Samsung), so the
          # greeter only appears on the secondary monitor.
          wayland.enable = false;
          # Mirrors config/hypr/hyprland.lua:4-16:
          #   HDMI-A-2 (LG 1920x1080) primary at 0x0
          #   DVI-D-2  (Samsung 1366x768) at 1920x0
          setupScript = ''
            ${pkgs.xrandr}/bin/xrandr --output HDMI-A-2 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
                   --output DVI-D-2 --mode 1366x768 --pos 1920x0 --rotate normal 2>&1 | systemd-cat -t sddm-xsetup || true
          '';
          extraPackages = [ sddm-astronaut ];
        };
        defaultSession = "hyprland";
      };

      # Required for X11 greeter; Hyprland itself still uses Wayland.
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];
    };
}
