{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      programs.bash = {
        completion.enable = true;
        blesh.enable = true;

        interactiveShellInit = lib.mkAfter ''
          # Less noisy than blesh default "[ble: EOF]" for files missing trailing newline.
          if [[ ''${BLE_VERSION-} ]]; then
            bleopt prompt_eol_mark=$'\e[90m⏎\e[m'
          fi

          shopt -s histappend checkwinsize
          HISTCONTROL=ignoreboth
          HISTSIZE=32768
          HISTFILESIZE=32768

          n() {
            if [ "$#" -eq 0 ]; then
              command nvim .
            else
              command nvim "$@"
            fi
          }

          open() (
            xdg-open "$@" >/dev/null 2>&1 &
          )
        '';
      };
    };
}
