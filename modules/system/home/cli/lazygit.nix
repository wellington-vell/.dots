{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.bash.shellAliases = {
        lg = "lazygit";
      };

      environment.systemPackages = [ pkgs.lazygit ];
    };
}
