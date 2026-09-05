{
  flake.modules.nixos.editors =
    { pkgs, ... }:
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.sessionVariables.EDITOR = "nvim";
      environment.sessionVariables.VISUAL = "nvim";

      # LazyVim starter from config/nvim — plugins install to ~/.local/share/nvim
      environment.etc."xdg/nvim".source = ../../../config/nvim;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      environment.systemPackages = with pkgs; [
        vscode
        code-cursor
        # LazyVim / mason tooling
        ripgrep
        fd
        lazygit
        gcc
        unzip
        wget
        curl
        tree-sitter
      ];
    };
}
