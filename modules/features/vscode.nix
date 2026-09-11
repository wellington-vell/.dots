{
  flake.modules.nixos.vscode =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      vscodePackage = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
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
      environment.systemPackages = [ vscodePackage ];

      system.activationScripts.vscodeConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/Code/User"
          ln -sfn ${lib.escapeShellArg "${dots}/config/vscode/settings.json"} "$home/.config/Code/User/settings.json"
          ln -sfn ${lib.escapeShellArg "${dots}/config/vscode/keybindings.json"} "$home/.config/Code/User/keybindings.json"
        done
      '';
    };
}
