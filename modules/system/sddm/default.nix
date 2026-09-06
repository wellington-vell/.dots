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
          wayland.enable = true;
          # SDDM astronaut pulls qtsvg/qtmultimedia/qtvirtualkeyboard via
          # propagatedBuildInputs, but sddm needs them at runtime explicitly
          # for some setups — keep sddm-astronaut in extraPackages as well.
          extraPackages = [ sddm-astronaut ];
        };
        defaultSession = "hyprland";
      };

      # X11 still needed for XWayland; SDDM itself now runs on Wayland.
      services.xserver.enable = true;
      services.xserver.excludePackages = [ pkgs.xterm ];
    };
}
