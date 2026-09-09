{
  flake.modules.nixos.sddm =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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

      # Build xrandr args from host.monitors (shared with Hyprland).
      xrandrArgs = lib.concatMapStringsSep " " (
        m:
        let
          modeFlag = lib.optionalString (m.mode != "preferred") " --mode ${m.mode}";
          primaryFlag = lib.optionalString m.primary " --primary";
        in
        "--output ${m.output}${primaryFlag}${modeFlag} --pos ${m.position} --rotate normal"
      ) config.host.monitors;

      setupScript =
        if config.host.monitors == [ ] then
          null
        else
          ''
            ${pkgs.xrandr}/bin/xrandr ${xrandrArgs} 2>&1 | systemd-cat -t sddm-xsetup || true
          '';
    in
    {
      environment.systemPackages = [ sddm-astronaut ];

      services.displayManager = {
        sddm = {
          enable = true;
          package = pkgs.kdePackages.sddm;
          theme = "sddm-astronaut-theme";
          # X11 greeter so xrandr setupScript can force primary; Weston
          # ignores xrandr and may pick the wrong DRM connector.
          wayland.enable = false;
          extraPackages = [ sddm-astronaut ];
        }
        // lib.optionalAttrs (setupScript != null) { inherit setupScript; };
        defaultSession = "hyprland";
      };

      # Required for X11 greeter; Hyprland itself still uses Wayland.
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];
    };
}
