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
      # Import (not legacyPackages) so allowUnfree applies to this nixpkgs instance.
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      cursorSettings = pkgs.writeText "cursor-settings.json" (
        builtins.toJSON {
          "window.autoDetectColorScheme" = true;
          "cursor.composer.usageSummaryDisplay" = "always";
          "workbench.iconTheme" = "material-icon-theme";
          "cursor.composer.shouldChimeAfterChatFinishes" = true;
          "terminal.integrated.shellIntegration.enabled" = false;
          "settingsSync.enable" = false;
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
          bbenoist.nix
          pkief.material-icon-theme
          eamodio.gitlens
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
