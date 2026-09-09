{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      programs.bash = {
        completion.enable = true;
        blesh.enable = true;

        shellAliases = {
          # Directories
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";

          # Tools
          c = "opencode";
          d = "docker";
          g = "git";
          t = "tmux attach || tmux new -s Work";

          # Git
          gcm = "git commit -m";
          gcam = "git commit -a -m";
          gcad = "git commit -a --amend";
        };

        interactiveShellInit = lib.mkAfter ''
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
