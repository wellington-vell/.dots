{
  inputs,
  ...
}:
{
  flake.modules.nixos.editors =
    { pkgs, ... }:
    let
      # 26.05 ships Cursor 3.5.x with laggy SCM commit input; unstable is past the 3.8 fix.
      unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
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
        unstable.code-cursor
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
