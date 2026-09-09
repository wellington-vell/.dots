{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.bash.shellAliases = {
        ls = "eza -lh --group-directories-first --icons=auto";
        lsa = "ls -a";
        lt = "eza --tree --level=2 --long --icons --git";
        lta = "lt -a";
      };

      environment.systemPackages = [ pkgs.eza ];
    };
}
