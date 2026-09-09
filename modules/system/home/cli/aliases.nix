{
  flake.modules.nixos.base = {
    programs.bash.shellAliases = {
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

      # eza
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -a";
      lt = "eza --tree --level=2 --long --icons --git";
      lta = "lt -a";

      # fzf
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      eff = ''$EDITOR "$(ff)"'';

      # lazygit
      lg = "lazygit";

      # ripgrep
      grep = "rg";

      # zoxide (zd defined in zoxide.nix interactiveShellInit)
      cd = "zd";
    };
  };
}
