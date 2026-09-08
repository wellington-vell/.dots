{
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

      wallpapers = ../../../assets/wallpapers;

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

      # Prefer Loupe over browsers for common image MIME types.
      xdg.mime.defaultApplications = {
        "image/png" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/jpg" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";
      };

      environment.systemPackages = [
        noctaliaScreenshotNotify
        pkgs.libnotify
        pkgs.xdg-utils
        pkgs.loupe
      ];

      # Hyprland integration (kept out of the shared compositor module).
      dotfiles.hyprland.extraLua = ''
        -- Noctalia --
        hl.on("hyprland.start", function ()
          hl.exec_cmd("noctalia")
        end)

        local mainMod = "SUPER"
        local noctaliaIpc = "noctalia msg "

        hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle clipboard"))
        hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle launcher"))
        hl.bind(mainMod .. " + CTRL + O", hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle control-center"))
        hl.bind(mainMod .. " + comma", function()
          local current = hl.get_config("general.layout") or "dwindle"
          if current == "scrolling" then
            hl.dispatch(hl.dsp.layout("swapcol l"))
          else
            hl.dispatch(hl.dsp.exec_cmd(noctaliaIpc .. "settings-toggle"))
          end
        end)
        hl.bind("ALT + Tab",           hl.dsp.exec_cmd(noctaliaIpc .. "window-switcher"))
        hl.bind("Print",               hl.dsp.exec_cmd(noctaliaIpc .. "screenshot-region"))
        hl.bind("SHIFT + Print",       hl.dsp.exec_cmd(noctaliaIpc .. "screenshot-fullscreen"))
        hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(noctaliaIpc .. "plugin noctalia/screen_recorder:service all toggle focused"))

        hl.window_rule({
            name  = "noctalia-settings",
            match = { class = "dev.noctalia.Noctalia" },
            float = true,
            size  = { 1080, 920 },
        })

        hl.layer_rule({
            name  = "noctalia-blur",
            match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
            no_anim     = true,
            ignore_alpha = 0.5,
            blur        = true,
            blur_popups = true,
        })
      '';
    };
}
