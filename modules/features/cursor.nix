{
  inputs,
  config,
  ...
}:
let
  inherit (config.flake.lib) mkEditorWrapper;
in
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

      cursorBin = mkEditorWrapper {
        inherit pkgs lib;
        inherit (unstable) vscode-extensions vscode-utils;
        name = "cursor";
        exe = lib.getExe unstable.code-cursor;
        processPattern = "/lib/cursor/cursor";
        # Store-path shell: Cursor agent sandbox hides /run/current-system.
        preamble = ''
          export SHELL="${pkgs.bashInteractive}/bin/bash"
        '';
        userExtensionsDir = ".cursor/extensions";
        extensionsDir = ".local/share/cursor-extensions";
        userDataDir = ".config/Cursor";
        dotsPath = dots;
      };

      # lndir does not overwrite: put our bin first so it wins over code-cursor's.
      cursorPackage = pkgs.symlinkJoin {
        name = "cursor-with-extensions";
        paths = [
          cursorBin
          unstable.code-cursor
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
          mkdir -p "$home/.config/Cursor/User" "$home/.cursor/extensions" "$home/.local/share/cursor-extensions"
          ln -sfn ${lib.escapeShellArg "${dots}/config/cursor/settings.json"} "$home/.config/Cursor/User/settings.json"
          ln -sfn ${lib.escapeShellArg "${dots}/config/cursor/keybindings.json"} "$home/.config/Cursor/User/keybindings.json"
          ln -sfn ${lib.escapeShellArg "${dots}/config/cursor/sandbox.json"} "$home/.cursor/sandbox.json"
          rm -f "$home/.cursor/extensions/.obsolete" "$home/.local/share/cursor-extensions/.obsolete"
          # Remove Nix symlinks mistakenly placed in the user extensions dir.
          find "$home/.cursor/extensions" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} +
        done
      '';
    };
}
