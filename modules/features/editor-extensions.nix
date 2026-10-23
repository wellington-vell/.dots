# Shared extension set, per-project profiles and launcher wrapper for the
# VS Code and Cursor features. A function so each editor resolves extensions
# from its own nixpkgs (Cursor tracks unstable).
{
  flake.lib.mkEditorWrapper =
    {
      pkgs,
      lib,
      vscode-extensions,
      vscode-utils,
      # Launcher name, also used for store names.
      name,
      # Editor binary the wrapper execs.
      exe,
      # Matched against running processes' command lines (pgrep -f).
      processPattern,
      # Paths relative to $HOME.
      userExtensionsDir,
      extensionsDir,
      userDataDir,
      preamble ? "",
      # This flake's checkout; opens in the Nix profile.
      dotsPath,
    }:
    let
      marketplace = vscode-utils.extensionsFromVscodeMarketplace;

      groups = with vscode-extensions; {
        # Enabled in every profile (application-scoped in the default one).
        base = [
          pkief.material-icon-theme
          eamodio.gitlens
          jnoortheen.nix-ide
          mkhl.direnv
          tamasfe.even-better-toml
        ]
        ++ marketplace [
          {
            name = "beardedtheme";
            publisher = "BeardedBear";
            version = "10.1.0";
            hash = "sha256-7MkvLEadzgB7af01lYibEOqHn9bvzlpgMTEiiQBlEzA=";
          }
        ];
        web = [
          formulahendry.auto-rename-tag
          meganrogge.template-string-converter
          oxc.oxc-vscode
          bradlc.vscode-tailwindcss
        ]
        ++ marketplace [
          {
            name = "native-preview";
            publisher = "typescriptteam";
            version = "0.20260708.2";
            arch = "linux-x64";
            hash = "sha256-1ZeBTtzUPfF5GwWY+clgQRoSvCAIj5jfPVn9Y/7PtfM=";
          }
        ];
        # templ components are HTML + Tailwind.
        go = [
          golang.go
          bradlc.vscode-tailwindcss
          formulahendry.auto-rename-tag
        ]
        ++ marketplace [
          {
            name = "templ";
            publisher = "a-h";
            version = "0.0.35";
            hash = "sha256-WIBJorljcnoPUrQCo1eyFb6vQ5lcxV0i+QJlJdzZYE0=";
          }
        ];
        rust = [ rust-lang.rust-analyzer ];
      };

      # Folders are relative to ~/Projects unless absolute. Anything else
      # opens in the default profile, which has every extension.
      profiles = {
        nix = {
          name = "Nix";
          groups = [ ];
          folders = [ dotsPath ];
        };
        go = {
          name = "Go";
          groups = [ "go" ];
          folders = [ "lindaflor" ];
        };
        web = {
          name = "Web";
          groups = [ "web" ];
          folders = [ "sepro" ];
        };
        rust = {
          name = "Rust";
          groups = [ "rust" ];
          folders = [ "wo-mic-linux" ];
        };
        web-rust = {
          name = "Web + Rust";
          groups = [
            "web"
            "rust"
          ];
          folders = [ "e2e-ts-rs" ];
        };
      };

      extensions = lib.unique (lib.concatLists (lib.attrValues groups));
      baseIds = map (e: e.vscodeExtUniqueId) groups.base;
      profileExtensions = p: lib.unique (lib.concatMap (g: groups.${g}) p.groups);

      defaultEntry =
        e:
        lib.recursiveUpdate (vscode-utils.toExtensionJsonEntry e) {
          metadata.isApplicationScoped = lib.elem e.vscodeExtUniqueId baseIds;
        };

      # Profiles share everything with the default profile except extensions.
      sharedFlags = lib.genAttrs [
        "settings"
        "keybindings"
        "tasks"
        "snippets"
        "prompts"
        "globalState"
        "mcp"
        "languageModels"
      ] (_: true);

      profilesJson = builtins.toJSON {
        profiles = lib.mapAttrsToList (id: p: {
          location = id;
          inherit (p) name;
          useDefaultFlags = sharedFlags;
        }) profiles;
        associations = lib.concatMapAttrs (id: p: lib.genAttrs p.folders (_: id)) profiles;
      };

      extensionsEnv = pkgs.buildEnv {
        name = "${name}-extensions";
        paths = extensions;
      };

      state = pkgs.linkFarm "${name}-extension-state" (
        [
          {
            name = "extensions.json";
            path = pkgs.writeText "${name}-extensions.json" (builtins.toJSON (map defaultEntry extensions));
          }
          {
            name = "profiles.json";
            path = pkgs.writeText "${name}-profiles.json" profilesJson;
          }
        ]
        ++ lib.mapAttrsToList (id: p: {
          name = "profiles/${id}/extensions.json";
          path = pkgs.writeText "${name}-${id}-extensions.json" (
            vscode-utils.toExtensionJson (profileExtensions p)
          );
        }) profiles
      );
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.jq
        pkgs.findutils
        pkgs.gnugrep
        pkgs.procps
      ];
      text = ''
        ${preamble}

        user_exts="$HOME/${userExtensionsDir}"
        ext_dir="$HOME/${extensionsDir}"
        user_data="$HOME/${userDataDir}/User"
        profiles_home="$user_data/profiles"
        storage="$user_data/globalStorage/storage.json"
        nix_exts="${extensionsEnv}/share/vscode/extensions"
        state="${state}"

        mkdir -p "$user_exts" "$ext_dir"

        rm -f "$ext_dir/.obsolete" "$user_exts/.obsolete"

        # Rebuilding while the editor runs makes it drop extensions (theme
        # resets) and it rewrites storage.json from memory on exit, so CLI
        # calls like `--install-extension` (Claude Code does this on start)
        # pass straight through. Only rebuild on a cold start when the Nix
        # set or user sideloads changed.
        stamp="$state $nix_exts $(find "$user_exts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tr '\n' ' ')"
        if [ "$(cat "$ext_dir/.nix-stamp" 2>/dev/null || true)" = "$stamp" ] ||
          pgrep -u "$(id -u)" -f -- ${lib.escapeShellArg processPattern} >/dev/null; then
          exec ${exe} --extensions-dir "$ext_dir" "$@"
        fi

        ext_id() { jq -r '((.publisher // "") + "." + (.name // "")) | ascii_downcase' "$1/package.json" 2>/dev/null || true; }
        ext_ver() { jq -r '.version // "0.0.0"' "$1/package.json" 2>/dev/null || echo "0.0.0"; }
        nix_ids=$(jq -r '.[].identifier.id | ascii_downcase' "$state/extensions.json")
        relocate() { jq --arg d "$ext_dir" 'map(.location.fsPath = ($d + "/" + .relativeLocation) | .location.path = .location.fsPath)' "$1"; }

        # Drop previous links; keep real dirs installed via --install-extension.
        find "$ext_dir" -mindepth 1 -maxdepth 1 -type l -exec rm -f {} +

        # Real dirs: delete marketplace copies of Nix extensions (auto-update
        # leftovers) and all but the newest version of each sideload.
        seen=""
        while IFS=$'\t' read -r id _ path; do
          if grep -qxF "$id" <<<"$nix_ids$seen"; then
            rm -rf -- "$path"
            continue
          fi
          seen+=$'\n'"$id"
        done < <(
          for path in "$ext_dir"/*/; do
            path=''${path%/}
            id=$(ext_id "$path")
            [ -n "$id" ] && [ "$id" != "." ] || continue
            printf '%s\t%s\t%s\n' "$id" "$(ext_ver "$path")" "$path"
          done | sort -t$'\t' -k1,1 -k2,2Vr
        )

        for path in "$nix_exts"/*; do
          [ -e "$path" ] || continue
          ln -sfn "$(readlink -f "$path")" "$ext_dir/$(basename "$path")"
        done

        # Real user dirs only (remote-ssh, …), unless already provided. Skip
        # stale Nix symlinks left in the user dir by older wrappers.
        for path in "$user_exts"/*; do
          [ -d "$path" ] && [ ! -L "$path" ] || continue
          id=$(ext_id "$path")
          [ -n "$id" ] && [ "$id" != "." ] || continue
          grep -qxF "$id" <<<"$nix_ids$seen" && continue
          seen+=$'\n'"$id"
          ln -sfn "$path" "$ext_dir/$(basename "$path")"
        done

        # Default profile: Nix set, then sideloads as application-scoped so
        # they show up in every profile.
        relocate "$state/extensions.json" >"$ext_dir/extensions.json.new"
        for path in "$ext_dir"/*/; do
          path=''${path%/}
          rel=$(basename "$path")
          id=$(ext_id "$path")
          [ -n "$id" ] && [ "$id" != "." ] || continue
          if jq -e --arg id "$id" 'any(.identifier.id | ascii_downcase == $id)' "$ext_dir/extensions.json.new" >/dev/null; then
            continue
          fi
          jq --arg id "$id" --arg ver "$(ext_ver "$path")" --arg path "$path" --arg rel "$rel" '
            . + [{
              identifier: { id: $id, uuid: "" },
              version: $ver,
              location: { "$mid": 1, fsPath: $path, path: $path, scheme: "file" },
              relativeLocation: $rel,
              metadata: {
                id: "",
                installedTimestamp: 0,
                isApplicationScoped: true,
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

        # Per-project profiles.
        for dir in "$state"/profiles/*/; do
          id=$(basename "$dir")
          mkdir -p "$profiles_home/$id"
          relocate "$dir/extensions.json" >"$profiles_home/$id/extensions.json"
        done

        # Register profiles and folder associations. Profiles removed from
        # Nix lose their entry and associations; other profiles and
        # associations made in the editor are kept.
        mkdir -p "$(dirname "$storage")"
        [ -s "$storage" ] || echo '{}' >"$storage"
        old=$(cat "$profiles_home/.nix-managed" 2>/dev/null || echo '[]')
        jq --argjson old "$old" --slurpfile p "$state/profiles.json" --arg projects "file://$HOME/Projects/" '
          $p[0] as $p
          | ($p.profiles | map(.location)) as $new
          | ($old - $new) as $removed
          | .userDataProfiles = [(.userDataProfiles // [])[] | select(.location as $l | ($old + $new) | index($l) | not)] + $p.profiles
          | .profileAssociations.workspaces = (
              ((.profileAssociations.workspaces // {}) | with_entries(select(.value as $v | $removed | index($v) | not)))
              + ($p.associations | with_entries(.key |= if startswith("/") then "file://" + . else $projects + . end))
            )
          | .profileAssociations.emptyWindows = (.profileAssociations.emptyWindows // {})
        ' "$storage" >"$storage.tmp"
        mv -f "$storage.tmp" "$storage"
        jq -c '.profiles | map(.location)' "$state/profiles.json" >"$profiles_home/.nix-managed"

        printf '%s' "$stamp" >"$ext_dir/.nix-stamp"

        exec ${exe} --extensions-dir "$ext_dir" "$@"
      '';
    };
}
