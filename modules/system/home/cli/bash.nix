{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    let
      # Literal store path — package values get rewritten to /run/current-system/sw/bin/bash.
      storeBash = "${pkgs.bashInteractive}/bin/bash";
    in
    {
      # Store-path shell so Cursor's agent sandbox can exec $SHELL. The sandbox
      # tmpfs-mounts over /run and hides /run/current-system/sw/bin.
      users.defaultUserShell = storeBash;
      environment.shells = [
        storeBash
        pkgs.bashInteractive
      ];
      environment.sessionVariables.SHELL = storeBash;

      # Match NixOS /bin/sh for tools that hardcode /bin/bash.
      systemd.tmpfiles.rules = [
        "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
      ];

      # mutableUsers=true does not rewrite an existing account's shell on switch.
      system.activationScripts.storePathShell = lib.stringAfter [ "users" ] ''
        store_bash=${lib.escapeShellArg storeBash}
        for user in $(${pkgs.gawk}/bin/awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' /etc/passwd); do
          current=$(${pkgs.getent}/bin/getent passwd "$user" | ${pkgs.coreutils}/bin/cut -d: -f7)
          if [ "$current" != "$store_bash" ]; then
            echo "setting shell for $user -> $store_bash"
            ${pkgs.shadow}/bin/usermod -s "$store_bash" "$user" || true
          fi
        done
      '';

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
