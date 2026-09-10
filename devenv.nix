{ pkgs, ... }:
{
  packages = [
    pkgs.nil
    pkgs.nixfmt
    pkgs.nixfmt-tree
  ];

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    printf "\033[1;34m▲ nixdots\033[0m devenv ready — %s\n" "$(devenv --version 2>/dev/null | head -n1)"
    printf "  \033[2mtools:\033[0m nil %s · nixfmt %s\n" "$(nil --version 2>/dev/null | awk '{print $2}')" "$(nixfmt --version 2>/dev/null | awk '{print $2}')"
    printf "  \033[2mtry:\033[0m \033[33mnix fmt\033[0m  \033[2m│\033[0m  \033[33mnix flake check\033[0m  \033[2m│\033[0m  \033[33mnixos-rebuild switch --flake .#alpha\033[0m\n"
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.nixfmt.enable = true;

  # https://devenv.sh/tests/
  enterTest = ''
    nil --version
    nixfmt --version
  '';
}
