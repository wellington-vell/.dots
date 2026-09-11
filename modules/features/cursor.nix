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

      dots = config.host.dotsPath;
    in
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = [ cursorPackage ];

      system.activationScripts.cursorConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/Cursor/User"
          ln -sfn ${lib.escapeShellArg "${dots}/config/cursor/settings.json"} "$home/.config/Cursor/User/settings.json"
          ln -sfn ${lib.escapeShellArg "${dots}/config/cursor/keybindings.json"} "$home/.config/Cursor/User/keybindings.json"
        done
      '';
    };
}
