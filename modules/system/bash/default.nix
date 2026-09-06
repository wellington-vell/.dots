{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      programs.bash = {
        completion.enable = true;
        blesh.enable = true;

        shellAliases = {
          # File system (eza / bat / fzf always packaged below)
          ls = "eza -lh --group-directories-first --icons=auto";
          lsa = "ls -a";
          lt = "eza --tree --level=2 --long --icons --git";
          lta = "lt -a";
          ff = "fzf --preview 'bat --style=numbers --color=always {}'";
          eff = ''$EDITOR "$(ff)"'';

          # Directories
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";

          # Tools
          c = "opencode";
          d = "docker";
          g = "git";
          t = "tmux attach || tmux new -s Work";
          grep = "rg";
          lg = "lazygit";

          # Git
          gcm = "git commit -m";
          gcam = "git commit -a -m";
          gcad = "git commit -a --amend";

          # zoxide-backed cd (zd defined in interactiveShellInit)
          cd = "zd";
        };

        interactiveShellInit = lib.mkAfter ''
          shopt -s histappend checkwinsize
          HISTCONTROL=ignoreboth
          HISTSIZE=32768
          HISTFILESIZE=32768

          if [[ ''${BLE_VERSION-} ]]; then
            _ble_contrib_fzf_base=${pkgs.fzf}/share/fzf
            ble-import -d integration/fzf-completion
            ble-import -d integration/fzf-key-bindings
          fi

          eval "$(zoxide init bash)"

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

          zd() {
            if (( $# == 0 )); then
              builtin cd ~ || return
            elif [[ -d $1 ]]; then
              builtin cd "$1" || return
            else
              if ! z "$@"; then
                echo "Error: Directory not found"
                return 1
              fi
              printf '\U000F17A9 '
              pwd
            fi
          }
        '';
      };

      environment.systemPackages = with pkgs; [
        fzf
        eza
        bat
        zoxide
        ripgrep
        fd
        lazygit
      ];

      programs.starship = {
        enable = true;
        settings = {
          add_newline = true;
          command_timeout = 200;
          format = "[$directory$git_branch$git_status]($style)$character";

          character = {
            error_symbol = "[✗](bold cyan)";
            success_symbol = "[❯](bold cyan)";
          };

          directory = {
            truncation_length = 2;
            truncation_symbol = "…/";
            repo_root_style = "bold cyan";
            repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
          };

          git_branch = {
            format = "[$branch]($style) ";
            style = "italic cyan";
          };

          git_status = {
            format = "[$all_status]($style)";
            style = "cyan";
            ahead = "⇡\${count} ";
            diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
            behind = "⇣\${count} ";
            conflicted = " ";
            up_to_date = " ";
            untracked = "? ";
            modified = " ";
            stashed = "";
            staged = "";
            renamed = "";
            deleted = "";
          };
        };
      };
    };
}
