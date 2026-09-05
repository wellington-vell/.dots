{
  flake.modules.nixos.hyprland =
    { pkgs, lib, ... }:
    let
      hyprlandConfig = ../../../config/hypr/hyprland.lua;

      wrapHyprland = pkg:
        let
          wrapped = pkgs.symlinkJoin {
            name = "hyprland-with-config";
            paths = [ pkg ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/Hyprland \
                --add-flags '--config ${hyprlandConfig}'
            '';
          };
        in
        wrapped
        // {
          override = lib.setFunctionArgs (args: wrapHyprland (pkg.override args)) (
            lib.functionArgs pkg.override
          );
          inherit (pkg) overrideAttrs version;
          passthru = pkg.passthru;
          providedSessions = pkg.passthru.providedSessions;
          meta = pkg.meta // {
            mainProgram = "Hyprland";
            outputsToInstall = [ "out" ];
          };
        };
    in
    {
      programs.hyprland = {
        enable = true;
        package = wrapHyprland pkgs.hyprland;
      };

      services.xserver.enable = true;
      services.displayManager = {
        sddm = {
          enable = true;
          wayland.enable = false;
        };
        defaultSession = "hyprland";
      };
    };
}
