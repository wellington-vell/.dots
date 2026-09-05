{
  flake.modules.nixos.lazydocker =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.lazydocker ];
    };
}
