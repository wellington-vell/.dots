{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.bash.shellAliases = {
        grep = "rg";
      };

      environment.systemPackages = [ pkgs.ripgrep ];
    };
}
