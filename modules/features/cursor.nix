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

      vscodeExtensions = with unstable.vscode-extensions; [
        pkief.material-icon-theme
        eamodio.gitlens
        formulahendry.auto-rename-tag
        meganrogge.template-string-converter
        oxc.oxc-vscode
        bradlc.vscode-tailwindcss
        jnoortheen.nix-ide
      ];

      # Same layout as vscode-with-extensions: unversioned dirs + extensions.json.
      extensionJsonFile = pkgs.writeTextFile {
        name = "cursor-extensions-json";
        destination = "/share/vscode/extensions/extensions.json";
        text = unstable.vscode-utils.toExtensionJson vscodeExtensions;
      };

      extensionsEnv = pkgs.buildEnv {
        name = "cursor-extensions";
        paths = vscodeExtensions ++ [ extensionJsonFile ];
      };

      # Combined dir: Nix extensions + writable Noctalia sideload + any marketplace
      # extras still under ~/.cursor/extensions. Avoids .obsolete on Nix links and
      # keeps Noctalia's template output path (~/.cursor/extensions/noctalia...) writable.
      cursorBin = pkgs.writeShellApplication {
        name = "cursor";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
          pkgs.findutils
        ];
        text = ''
          user_exts="$HOME/.cursor/extensions"
          nix_exts="${extensionsEnv}/share/vscode/extensions"
          ext_dir="$HOME/.local/share/cursor-extensions"

          mkdir -p "$user_exts" "$ext_dir"

          # Drop previous combined links; recreate from Nix + user sideloads.
          find "$ext_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

          if [ -d "$nix_exts" ]; then
            for path in "$nix_exts"/*; do
              [ -e "$path" ] || continue
              name=$(basename "$path")
              [ "$name" = "extensions.json" ] && continue
              ln -sfn "$(readlink -f "$path")" "$ext_dir/$name"
            done
          fi

          # Real user dirs only (Noctalia sideload, remote-ssh, …). Skip stale
          # Nix symlinks left in ~/.cursor/extensions from older wrappers.
          if [ -d "$user_exts" ]; then
            for path in "$user_exts"/*; do
              [ -e "$path" ] || continue
              [ -L "$path" ] && continue
              [ -d "$path" ] || continue
              name=$(basename "$path")
              # Marketplace -universal copy is not where Noctalia writes themes.
              case "$name" in
                noctalia.*-universal) continue ;;
              esac
              ln -sfn "$path" "$ext_dir/$name"
            done
          fi

          # Register Nix extensions; rewrite locations to the combined dir.
          if [ -f "$nix_exts/extensions.json" ]; then
            jq --arg d "$ext_dir" '
              map(
                .location.fsPath = ($d + "/" + .relativeLocation)
                | .location.path = .location.fsPath
              )
            ' "$nix_exts/extensions.json" >"$ext_dir/extensions.json"
          else
            echo '[]' >"$ext_dir/extensions.json"
          fi

          # Append surviving user extensions not already listed.
          for path in "$ext_dir"/*; do
            [ -d "$path" ] || continue
            name=$(basename "$path")
            [ "$name" = "extensions.json" ] && continue
            id=$(jq -r '((.publisher // "") + "." + (.name // "")) | ascii_downcase' "$path/package.json" 2>/dev/null || true)
            ver=$(jq -r '.version // "0.0.0"' "$path/package.json" 2>/dev/null || echo "0.0.0")
            [ -n "$id" ] && [ "$id" != "null.null" ] || continue
            if jq -e --arg id "$id" 'any(.identifier.id == $id)' "$ext_dir/extensions.json" >/dev/null; then
              continue
            fi
            jq --arg id "$id" --arg ver "$ver" --arg path "$path" --arg rel "$name" '
              . + [{
                identifier: { id: $id, uuid: "" },
                version: $ver,
                location: { "$mid": 1, fsPath: $path, path: $path, scheme: "file" },
                relativeLocation: $rel,
                metadata: {
                  id: "",
                  installedTimestamp: 0,
                  isApplicationScoped: false,
                  isPreReleaseVersion: false,
                  publisherDisplayName: ($id | split(".")[0]),
                  publisherId: "",
                  targetPlatform: "undefined",
                  updated: false
                }
              }]
            ' "$ext_dir/extensions.json" >"$ext_dir/extensions.json.tmp"
            mv -f "$ext_dir/extensions.json.tmp" "$ext_dir/extensions.json"
          done

          rm -f "$ext_dir/.obsolete" "$user_exts/.obsolete"

          exec ${lib.getExe unstable.code-cursor} --extensions-dir "$ext_dir" "$@"
        '';
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
          rm -f "$home/.cursor/extensions/.obsolete" "$home/.local/share/cursor-extensions/.obsolete"
          # Remove Nix symlinks mistakenly placed in the user extensions dir.
          find "$home/.cursor/extensions" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} +
        done
      '';
    };
}
