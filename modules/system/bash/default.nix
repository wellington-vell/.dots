{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      programs.bash = {
        completion.enable = true;
        blesh.enable = true;

        # Useful interactive defaults + ble.sh fzf integration (NixOS-aware paths)
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

          if command -v zoxide &>/dev/null; then
            eval "$(zoxide init bash)"
          fi

          source ${../../../config/bash/aliases.sh}
        '';
      };

      environment.systemPackages = with pkgs; [
        fzf
        eza
        bat
        zoxide
      ];

      # Omarchy-style Starship prompt
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
