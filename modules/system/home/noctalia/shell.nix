{
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.noctalia =
    {
      pkgs,
      lib,
      ...
    }:
    let
      toml = pkgs.formats.toml { };

      # Noctalia's built-in "Screenshot saved" toast has no open action.
      # Pipe the capture into this helper so click/Open runs Loupe directly
      # (xdg-open would hit Chromium's image/png MIME claim on this system).
      noctaliaScreenshotNotify = pkgs.writeShellApplication {
        name = "noctalia-screenshot-notify";
        runtimeInputs = [
          pkgs.libnotify
          pkgs.loupe
        ];
        text = ''
          # Drain PNG stdin from Noctalia's pipe_command.
          cat >/dev/null
          path="''${NOCTALIA_SCREENSHOT_PATH:-}"
          if [[ -z "$path" || ! -f "$path" ]]; then
            exit 0
          fi
          action="$(notify-send \
            --app-name=Screenshot \
            --icon="$path" \
            --action=default=Open \
            --wait \
            --expire-time=10000 \
            "Screenshot saved" \
            "$path")"
          if [[ "$action" == "default" ]]; then
            loupe "$path"
          fi
        '';
      };

      wallpapers = "${self}/assets/wallpapers";

      settings = {
        bar.default = {
          start = [
            "control-center"
            "launcher"
            "wallpaper"
            "workspaces"
          ];
          end = [
            "media"
            "tray"
            "notifications"
            "clipboard"
            "screenshot"
            "noctalia/screen_recorder:recorder"
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "battery"
            "session"
          ];
        };

        wallpaper = {
          directory = "${wallpapers}";
          default.path = "${wallpapers}/nix-wallpaper-moonscape.png";
        };

        widget.media.hide_when_no_media = true;
        widget.network.show_label = false;

        plugins.enabled = [ "noctalia/screen_recorder" ];
        plugin_settings."noctalia/screen_recorder".video_source = "focused";

        shell.screenshot = {
          pipe_to_command = true;
          pipe_command = lib.getExe noctaliaScreenshotNotify;
        };

        notification.filter."hide-screenshot-saved" = {
          enabled = true;
          match = "Noctalia";
          match_content = "Screenshot saved";
          show_toast = false;
          play_sound = false;
        };

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "caffeine"; }
          { type = "nightlight"; }
          { type = "notification"; }
          { type = "power_profile"; }
          { type = "screen_recorder"; }
        ];
      };

      noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Store-managed config home: Noctalia reads $NOCTALIA_CONFIG_HOME/noctalia/*.toml
      # (no ~/.config symlink / activationScripts).
      configHome =
        let
          configToml = toml.generate "config.toml" settings;
        in
        pkgs.runCommand "noctalia-config-home" { } ''
          ${lib.getExe noctaliaPkg} config validate ${configToml}
          mkdir -p $out/noctalia
          ln -s ${configToml} $out/noctalia/config.toml
        '';

      noctaliaWrapped = pkgs.symlinkJoin {
        name = "noctalia-with-config";
        paths = [ noctaliaPkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/noctalia \
            --set NOCTALIA_CONFIG_HOME ${configHome}
        '';
      };
    in
    {
      imports = [ inputs.noctalia.nixosModules.default ];

      programs.noctalia = {
        enable = true;
        package = noctaliaWrapped;
        recommendedServices.enable = true;
      };

      # Installs gpu-screen-recorder and wraps gsr-kms-server with cap_sys_admin.
      programs.gpu-screen-recorder.enable = true;

      environment.systemPackages = [
        noctaliaScreenshotNotify
        pkgs.libnotify
        pkgs.xdg-utils
        pkgs.loupe
      ];
    };
}
