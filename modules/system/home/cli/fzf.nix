{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      programs.bash = {
        shellAliases = {
          ff = "fzf --preview 'bat --style=numbers --color=always {}'";
          eff = ''$EDITOR "$(ff)"'';
        };

        interactiveShellInit = lib.mkAfter ''
          if [[ ''${BLE_VERSION-} ]]; then
            _ble_contrib_fzf_base=${pkgs.fzf}/share/fzf
            ble-import -d integration/fzf-completion
            ble-import -d integration/fzf-key-bindings
          fi
        '';
      };

      environment.systemPackages = [ pkgs.fzf ];
    };
}
