{
  inputs,
  ...
}:
{
  flake.modules.nixos.vscode =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "vscode" ];
      };
      vscodeVersion = "1.127.0";
      vscodeRev = "4fe60c8b1cdac1c4c174f2fb180d0d758272d713";
      vscodeBase = unstable.vscode.overrideAttrs (old: {
        version = vscodeVersion;
        src = pkgs.fetchurl {
          name = "VSCode_${vscodeVersion}_linux-x64.tar.gz";
          url = "https://update.code.visualstudio.com/${vscodeVersion}/linux-x64/stable";
          hash = "sha256-4G+zZ5HJuvdJXUt9wPWqqCVOfRpgpe5D5sfevAXJYrU=";
        };
        passthru = old.passthru // {
          rev = vscodeRev;
          vscodeServer = pkgs.srcOnly {
            name = "vscode-server-${vscodeRev}.tar.gz";
            src = pkgs.fetchurl {
              name = "vscode-server-${vscodeRev}.tar.gz";
              url = "https://update.code.visualstudio.com/commit:${vscodeRev}/server-linux-x64/stable";
              hash = "sha256-JpcbzKdVlfRRKCzG/aDoWEGG7Yg0BcjuqCcg/Nez/9U=";
            };
            stdenv = pkgs.stdenvNoCC;
          };
        };
      });
      vscodeExtensions =
        with pkgs.vscode-extensions;
        [
          pkief.material-icon-theme
          eamodio.gitlens
          formulahendry.auto-rename-tag
          meganrogge.template-string-converter
          oxc.oxc-vscode
          bradlc.vscode-tailwindcss
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          mkhl.direnv
          tamasfe.even-better-toml
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "beardedtheme";
            publisher = "BeardedBear";
            version = "10.1.0";
            hash = "sha256-7MkvLEadzgB7af01lYibEOqHn9bvzlpgMTEiiQBlEzA=";
          }
          {
            name = "native-preview";
            publisher = "typescriptteam";
            version = "0.20260708.2";
            arch = "linux-x64";
            hash = "sha256-1ZeBTtzUPfF5GwWY+clgQRoSvCAIj5jfPVn9Y/7PtfM=";
          }
        ];

      extensionJsonFile = pkgs.writeTextFile {
        name = "vscode-extensions-json";
        destination = "/share/vscode/extensions/extensions.json";
        text = pkgs.vscode-utils.toExtensionJson vscodeExtensions;
      };

      extensionsEnv = pkgs.buildEnv {
        name = "vscode-extensions";
        paths = vscodeExtensions ++ [ extensionJsonFile ];
      };

      codeBin = pkgs.writeShellApplication {
        name = "code";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
          pkgs.findutils
        ];
        text = ''
          user_exts="$HOME/.vscode/extensions"
          nix_exts="${extensionsEnv}/share/vscode/extensions"
          ext_dir="$HOME/.local/share/code-extensions"

          mkdir -p "$user_exts" "$ext_dir"

          rm -f "$ext_dir/.obsolete" "$user_exts/.obsolete"

          # Rebuilding while the editor runs makes it drop extensions (theme
          # resets), and CLI calls like `--install-extension` (Claude Code does
          # this on start) go through this wrapper too. Only rebuild when the
          # Nix set or user sideloads changed.
          stamp="$nix_exts $(find "$user_exts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tr '\n' ' ')"
          if [ "$(cat "$ext_dir/.nix-stamp" 2>/dev/null || true)" = "$stamp" ]; then
            exec ${lib.getExe vscodeBase} --extensions-dir "$ext_dir" "$@"
          fi

          # Drop previous links; keep real dirs installed via --install-extension.
          find "$ext_dir" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} +

          if [ -d "$nix_exts" ]; then
            for path in "$nix_exts"/*; do
              [ -e "$path" ] || continue
              name=$(basename "$path")
              [ "$name" = "extensions.json" ] && continue
              ln -sfn "$(readlink -f "$path")" "$ext_dir/$name"
            done
          fi

          if [ -d "$user_exts" ]; then
            for path in "$user_exts"/*; do
              [ -e "$path" ] || continue
              [ -L "$path" ] && continue
              [ -d "$path" ] || continue
              name=$(basename "$path")
              ln -sfn "$path" "$ext_dir/$name"
            done
          fi

          if [ -f "$nix_exts/extensions.json" ]; then
            jq --arg d "$ext_dir" '
              map(
                .location.fsPath = ($d + "/" + .relativeLocation)
                | .location.path = .location.fsPath
              )
            ' "$nix_exts/extensions.json" >"$ext_dir/extensions.json.new"
          else
            echo '[]' >"$ext_dir/extensions.json.new"
          fi

          for path in "$ext_dir"/*; do
            [ -d "$path" ] || continue
            name=$(basename "$path")
            [ "$name" = "extensions.json" ] && continue
            id=$(jq -r '((.publisher // "") + "." + (.name // "")) | ascii_downcase' "$path/package.json" 2>/dev/null || true)
            ver=$(jq -r '.version // "0.0.0"' "$path/package.json" 2>/dev/null || echo "0.0.0")
            [ -n "$id" ] && [ "$id" != "null.null" ] || continue
            if jq -e --arg id "$id" 'any(.identifier.id == $id)' "$ext_dir/extensions.json.new" >/dev/null; then
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
            ' "$ext_dir/extensions.json.new" >"$ext_dir/extensions.json.tmp"
            mv -f "$ext_dir/extensions.json.tmp" "$ext_dir/extensions.json.new"
          done
          mv -f "$ext_dir/extensions.json.new" "$ext_dir/extensions.json"
          printf '%s' "$stamp" >"$ext_dir/.nix-stamp"

          exec ${lib.getExe vscodeBase} --extensions-dir "$ext_dir" "$@"
        '';
      };

      vscodePackage = pkgs.symlinkJoin {
        name = "vscode-with-extensions";
        paths = [
          codeBin
          vscodeBase
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
      environment.systemPackages = [ vscodePackage ];

      system.activationScripts.vscodeConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/Code/User" "$home/.vscode/extensions" "$home/.local/share/code-extensions"
          ln -sfn ${lib.escapeShellArg "${dots}/config/vscode/settings.json"} "$home/.config/Code/User/settings.json"
          ln -sfn ${lib.escapeShellArg "${dots}/config/vscode/keybindings.json"} "$home/.config/Code/User/keybindings.json"
          rm -f "$home/.vscode/extensions/.obsolete" "$home/.local/share/code-extensions/.obsolete"
          find "$home/.vscode/extensions" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} +
        done
      '';
    };
}
