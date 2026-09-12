{
  flake.modules.nixos.base =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      settings = {
        add_newline = false;
        command_timeout = 200;
        format = "[$directory$git_branch$git_status]($style)$character";
        palette = "noctalia";

        character = {
          error_symbol = "[✗](bold cyan)";
          success_symbol = "[❯](bold cyan)";
        };

        directory = {
          truncation_length = 2;
          truncation_symbol = "…/";
          repo_root_style = "bold cyan";
          repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
        };

        git_branch = {
          format = "[$branch]($style) ";
          style = "italic cyan";
        };

        git_status = {
          format = "[$all_status]($style)";
          style = "cyan";
          ahead = "⇡\${count} ";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
          behind = "⇣\${count} ";
          conflicted = " ";
          up_to_date = " ";
          untracked = "? ";
          modified = " ";
          stashed = "";
          staged = "";
          renamed = "";
          deleted = "";
        };
      };

      settingsFile = (pkgs.formats.toml { }).generate "starship.toml" settings;

      # Noctalia's theme hook writes ~/.config/starship.toml (palette only when
      # missing). NixOS only exports STARSHIP_CONFIG when that path is absent, so
      # a palette-only file falls back to Starship defaults ($line_break +
      # add_newline) — blank/extra prompt line in Ghostty. Seed a writable file
      # with our settings; Noctalia's apply.sh preserves the body and refreshes
      # the palette markers.
      normalUsers = lib.filter (u: u.isNormalUser) (lib.attrValues config.users.users);
    in
    {
      programs.starship = {
        enable = true;
        inherit settings;
      };

      # Point Noctalia's starship apply.sh at the writable file we seed below so
      # it skips the ~1s /proc/*/environ scan (STARSHIP_CONFIG unset otherwise).
      environment.sessionVariables.STARSHIP_CONFIG = "$HOME/.config/starship.toml";

      # Activation PATH has no sed/cmp — only use shell builtins + coreutils
      # already on the activate PATH (mkdir, cp, chmod, chown, cat).
      system.activationScripts.starshipConfig = lib.stringAfter [ "users" ] ''
        ${lib.concatMapStringsSep "\n" (u: ''
          mkdir -p ${lib.escapeShellArg "${u.home}/.config"}
          target=${lib.escapeShellArg "${u.home}/.config/starship.toml"}
          palette=${lib.escapeShellArg "${u.home}/.cache/noctalia/starship-palette.toml"}
          {
            cat ${settingsFile}
            if [ -f "$palette" ]; then
              printf '\n# >>> NOCTALIA STARSHIP PALETTE >>>\n'
              cat "$palette"
              printf '# <<< NOCTALIA STARSHIP PALETTE <<<\n'
            fi
          } >"$target"
          chown --reference=${lib.escapeShellArg u.home} "$target"
          chmod 644 "$target"
        '') normalUsers}
      '';
    };
}
