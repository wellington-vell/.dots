{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      programs.bash = {
        interactiveShellInit = lib.mkAfter ''
          eval "$(zoxide init bash)"

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

      environment.systemPackages = [ pkgs.zoxide ];
    };
}
