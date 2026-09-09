{
  flake.modules.nixos.hyprland =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hyprlandConfig = pkgs.writeText "hyprland.lua" (
        lib.concatMapStrings (name: config.host.hyprland.fragments.${name} or "") [
          "monitors"
          "look"
          "input"
          "binds"
          "rules"
        ]
        + config.host.hyprland.extraLua
      );

      wrapHyprland =
        pkg:
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
      options.host.hyprland = {
        fragments = lib.mkOption {
          type = lib.types.attrsOf lib.types.lines;
          default = { };
          description = "Named Lua fragments assembled into the wrapped Hyprland config (order: monitors, look, input, binds, rules).";
        };

        extraLua = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Lua appended to the wrapped Hyprland config (shells inject autostart/binds/rules).";
        };
      };

      config = {
        programs.hyprland = {
          enable = true;
          package = wrapHyprland pkgs.hyprland;
        };

        environment.systemPackages = [
          pkgs.hyprpicker
          pkgs.wl-clipboard
          pkgs.wtype
        ];
      };
    };
}
