{
  flake.modules.nixos.vscode =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      vscodeSettings = pkgs.writeText "vscode-settings.json" (
        builtins.toJSON {
          "workbench.editor.empty.hint" = "hidden";
          "workbench.sideBar.location" = "right";
          "workbench.activityBar.location" = "top";
          "workbench.iconTheme" = "material-icon-theme";
          
          "diffEditor.ignoreTrimWhitespace" = false;
          
          "terminal.integrated.shellIntegration.enabled" = false;
          
          "settingsSync.enable" = false;
          
          "editor.lineNumbers" = "interval";
          "editor.minimap.enabled" = false;
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
        }
      );

      vscodeKeybindings = pkgs.writeText "vscode-keybindings.json" (builtins.toJSON [ ]);

      vscodePackage = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          pkief.material-icon-theme
          eamodio.gitlens
          formulahendry.auto-rename-tag
          meganrogge.template-string-converter
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
      environment.systemPackages = [ vscodePackage ];

      system.activationScripts.vscodeConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/Code/User"
          ln -sfn ${vscodeSettings} "$home/.config/Code/User/settings.json"
          ln -sfn ${vscodeKeybindings} "$home/.config/Code/User/keybindings.json"
        done
      '';
    };
}
