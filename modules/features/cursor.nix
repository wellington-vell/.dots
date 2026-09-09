{
  inputs,
  ...
}:
{
  flake.modules.nixos.cursor =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # 26.05 ships Cursor 3.5.x with laggy SCM commit input; unstable is past the 3.8 fix.
      # Import (not legacyPackages) so allowUnfreePredicate applies to this nixpkgs instance.
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "cursor"
            "vscode"
          ];
      };

      cursorSettings = pkgs.writeText "cursor-settings.json" (
        builtins.toJSON {
          "cursor.composer.usageSummaryDisplay" = "always";
          "cursor.composer.shouldChimeAfterChatFinishes" = true;
          "cursor.cpp.disabledLanguages" = [ "plaintext" ];

          "window.autoDetectColorScheme" = true;

          "workbench.iconTheme" = "material-icon-theme";

          "terminal.integrated.shellIntegration.enabled" = false;

          "settingsSync.enable" = false;

          "editor.lineNumbers" = "interval";
          "editor.cursorBlinking" = "solid";
          "editor.cursorSmoothCaretAnimation" = "on";
          "editor.cursorStyle" = "line-thin";

          "gitlens.telemetry.enabled" = false;
          "gitlens.views.scm.grouped.views" = {
            "commits" = true;
            "branches" = false;
            "remotes" = false;
            "stashes" = false;
            "tags" = true;
            "worktrees" = true;
            "contributors" = true;
            "fileHistory" = false;
            "repositories" = true;
            "searchAndCompare" = false;
            "launchpad" = true;
          };

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";
          "nix.serverSettings" = {
            "nil" = {
              formatting.command = [ "nixfmt" ];
              nix.flake.autoArchive = true;
              nix.flake.autoEvalInputs = true;
            };
          };
        }
      );

      cursorKeybindings = pkgs.writeText "cursor-keybindings.json" (
        builtins.toJSON [
          {
            key = "ctrl+e";
            command = "-cursor.toggleAgentWindowIDEUnification";
            when = "!isGlass && workbenchState != 'empty'";
          }
          {
            key = "ctrl+j";
            command = "-workbench.action.togglePanel";
            when = "!isAuxiliaryWindowFocusedContext";
          }
        ]
      );

      cursorPackage = unstable.vscode-with-extensions.override {
        vscode = unstable.code-cursor;
        vscodeExtensions = with unstable.vscode-extensions; [
          pkief.material-icon-theme
          eamodio.gitlens
          formulahendry.auto-rename-tag
          meganrogge.template-string-converter
          oxc.oxc-vscode
          bradlc.vscode-tailwindcss
          jnoortheen.nix-ide
        ];
      };

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = [ cursorPackage ];

      system.activationScripts.cursorConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/Cursor/User"
          ln -sfn ${cursorSettings} "$home/.config/Cursor/User/settings.json"
          ln -sfn ${cursorKeybindings} "$home/.config/Cursor/User/keybindings.json"
        done
      '';
    };
}
