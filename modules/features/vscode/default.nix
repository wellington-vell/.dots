{
  flake.modules.nixos.vscode =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      vscodeSettings = ../../../config/vscode/settings.json;
      vscodeKeybindings = ../../../config/vscode/keybindings.json;

      vscodePackage = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
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
