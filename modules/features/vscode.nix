{
  inputs,
  config,
  ...
}:
let
  inherit (config.flake.lib) mkEditorWrapper;
in
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
      codeBin = mkEditorWrapper {
        inherit pkgs lib;
        inherit (pkgs) vscode-extensions vscode-utils;
        name = "code";
        exe = lib.getExe vscodeBase;
        processPattern = "/lib/vscode/code";
        userExtensionsDir = ".vscode/extensions";
        extensionsDir = ".local/share/code-extensions";
        userDataDir = ".config/Code";
        dotsPath = dots;
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
