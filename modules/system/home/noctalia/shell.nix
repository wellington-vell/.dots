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
      config,
      ...
    }:
    let
      toml = pkgs.formats.toml { };

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];

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

      phonebridgePkg = inputs.phonebridge.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Default browser for Zen soft-relaunch (host.apps.browser).
      defaultBrowser = config.host.apps.browser;

      # After templates rewrite theme files, nudge running apps to pick them up.
      # Keep this fast: no full hyprctl reload, no duplicate Ghostty reload.
      noctaliaOnColorsChanged = pkgs.writeShellApplication {
        name = "noctalia-on-colors-changed";
        runtimeInputs = [
          pkgs.hyprland
          pkgs.procps
          pkgs.coreutils
        ];
        text = ''
          # Ensure hyprctl can reach the compositor when hooks inherit a thin env.
          if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            for d in "$runtime"/hypr/*/; do
              [ -d "$d" ] || continue
              HYPRLAND_INSTANCE_SIGNATURE="$(basename "$d")"
              export HYPRLAND_INSTANCE_SIGNATURE
              break
            done
          fi

          # Hyprland Lua mode rejects `keyword`; re-run noctalia.lua's apply_theme.
          noctalia_lua="$HOME/.config/hypr/noctalia.lua"
          if [ -f "$noctalia_lua" ]; then
            hyprctl eval "local m = dofile([[$noctalia_lua]]); if type(m) == [[table]] and type(m.apply_theme) == [[function]] then m.apply_theme() end" \
              >/dev/null 2>&1 || true
          fi

          # LazyVim / neovim: community apply.sh also signals; nudge again after writes.
          pkill -SIGUSR1 -x nvim >/dev/null 2>&1 || true

          # Zen: no CSS hot-reload — soft-relaunch running instances (session restore).
          # Ghostty reload is handled by the builtin ghostty apply.sh; do not duplicate.
          browser=${lib.escapeShellArg defaultBrowser}
          if pgrep -x zen-beta >/dev/null 2>&1 || pgrep -x zen >/dev/null 2>&1; then
            (
              pkill -x zen-beta >/dev/null 2>&1 || pkill -x zen >/dev/null 2>&1 || true
              sleep 0.4
              command -v "$browser" >/dev/null 2>&1 && exec "$browser"
            ) >/dev/null 2>&1 &
          fi
        '';
      };

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
            "wellington-vell/phonebridge:toggle"
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

        # Feeds Weather, Night Light, and Theme auto (not host.timeZone —
        # clocks already follow the system TZ from host.timeZone).
        location.auto_locate = true;

        # App theming: IDs only — palette/mode stay in settings.toml (GUI).
        # After rebuild, drop [theme.templates] from settings.toml so it cannot
        # shadow this list (arrays replace wholesale, they do not merge).
        theme.templates = {
          enable_builtin_templates = true;
          enable_community_templates = true;
          builtin_ids = [
            "gtk3"
            "gtk4"
            "ghostty"
            "hyprland"
            "kcolorscheme"
            "qt"
            "starship"
          ];
          community_ids = [
            "opencode"
            "neovim"
            "zen-browser"
            "obsidian"
            "steam"
            "fzf"
            "lazygit"
          ];
        };

        # Builtin ghostty apply.sh reloads the terminal; hyprland/neovim/zen
        # need the colors_changed hook below for live / soft-relaunch updates.
        # Stable /etc path so rebuilds update the script without a Noctalia restart
        # (store-absolute paths stay frozen in the long-lived daemon env).
        hooks.colors_changed = [ "/etc/noctalia/on-colors-changed" ];

        widget.media.hide_when_no_media = true;
        widget.network.show_label = false;

        plugins.enabled = [
          "noctalia/screen_recorder"
          "wellington-vell/phonebridge"
        ];
        # Declaring sources replaces Noctalia's defaults, so keep official +
        # community listed. The Phonebridge bar toggle ships inside its package.
        plugins.source = [
          {
            name = "official";
            kind = "git";
            location = "https://github.com/noctalia-dev/official-plugins";
            enabled = true;
          }
          {
            name = "community";
            kind = "git";
            location = "https://github.com/noctalia-dev/community-plugins";
            enabled = true;
          }
          {
            name = "phonebridge";
            kind = "path";
            location = "${phonebridgePkg}/share/noctalia-plugins";
            enabled = true;
          }
        ];
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

      qt6ctConfFor =
        home:
        pkgs.writeText "qt6ct.conf" ''
          [Appearance]
          custom_palette=true
          color_scheme_path=${home}/.config/qt6ct/colors/noctalia.conf
          style=Fusion
        '';

      # Minimal placeholders so first login before a template resolve is safe.
      hyprNoctaliaSeed = pkgs.writeText "noctalia.lua" ''
        -- Seeded until Noctalia's hyprland template overwrites this file.
        return {
          apply_theme = function() end,
        }
      '';

      ghosttyThemeSeed = pkgs.writeText "ghostty-noctalia-theme" ''
        # Seeded until Noctalia's ghostty template overwrites this file.
        background = #1a1b26
        foreground = #c0caf5
      '';

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
            --set NOCTALIA_CONFIG_HOME /etc/noctalia-config-home \
            --run 'export STARSHIP_CONFIG="''${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"'
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

      environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

      # Stable paths: long-lived Noctalia keeps env from launch; /etc symlinks
      # update on rebuild so hooks/config track the new generation.
      environment.etc."noctalia-config-home".source = configHome;
      environment.etc."noctalia/on-colors-changed".source = lib.getExe noctaliaOnColorsChanged;

      environment.systemPackages = [
        noctaliaScreenshotNotify
        pkgs.libnotify
        pkgs.xdg-utils
        pkgs.loupe
        pkgs.adw-gtk3
        pkgs.kdePackages.qt6ct
      ];

      # Writable theme targets + qt6ct pointing at Noctalia's generated scheme.
      # Do not manage gtk.css / qt colors — Noctalia's apply hooks own those.
      # (Activation PATH has no sed — bake home into qt6ct.conf at eval time.)
      system.activationScripts.noctaliaTheming = lib.stringAfter [ "users" ] (
        lib.concatMapStrings (
          home:
          let
            h = lib.escapeShellArg home;
          in
          ''
            mkdir -p ${h}/.config/hypr \
                     ${h}/.config/ghostty/themes \
                     ${h}/.config/qt6ct/colors

            # Store --config is authoritative; a leftover local hyprland.lua makes
            # Noctalia's apply.sh prefer lua-mode patching of a dead file.
            rm -f ${h}/.config/hypr/hyprland.lua

            if [ ! -e ${h}/.config/hypr/noctalia.lua ]; then
              cp ${hyprNoctaliaSeed} ${h}/.config/hypr/noctalia.lua
              chmod u+w ${h}/.config/hypr/noctalia.lua
            fi

            if [ ! -e ${h}/.config/ghostty/themes/noctalia ]; then
              cp ${ghosttyThemeSeed} ${h}/.config/ghostty/themes/noctalia
              chmod u+w ${h}/.config/ghostty/themes/noctalia
            fi

            ln -sfn ${qt6ctConfFor home} ${h}/.config/qt6ct/qt6ct.conf

            # Editors use Bearded Theme now — drop the old Noctalia sideload so
            # VS Code / Cursor fall back to the Nix-provided BeardedBear theme.
            rm -rf ${h}/.vscode/extensions/noctalia.noctaliatheme-0.0.5 \
                   ${h}/.vscode/extensions/noctalia.noctaliatheme-*-universal \
                   ${h}/.cursor/extensions/noctalia.noctaliatheme-0.0.5 \
                   ${h}/.cursor/extensions/noctalia.noctaliatheme-*-universal

            chown -R --reference=${h} \
              ${h}/.config/hypr \
              ${h}/.config/ghostty \
              ${h}/.config/qt6ct \
              2>/dev/null || true
          ''
        ) normalHomes
      );

      # Soft-relaunch Noctalia so it picks up the new wrapper /etc config home.
      system.activationScripts.noctaliaRelaunch = lib.stringAfter [ "noctaliaTheming" ] ''
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/1000}"
        if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          for d in "$XDG_RUNTIME_DIR"/hypr/*/; do
            [ -d "$d" ] || continue
            HYPRLAND_INSTANCE_SIGNATURE="$(basename "$d")"
            export HYPRLAND_INSTANCE_SIGNATURE
            break
          done
        fi
        if command -v hyprctl >/dev/null 2>&1 && [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          hyprctl dispatch 'hl.dsp.exec_cmd("sh -c '"'"'pkill -f /bin/noctalia || true; pkill -f [.]noctalia-wrapped || true; sleep 0.2; exec noctalia'"'"'")' \
            >/dev/null 2>&1 || true
        fi
      '';
    };
}
