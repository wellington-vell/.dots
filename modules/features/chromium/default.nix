{
  flake.modules.nixos.chromium =
    { pkgs, ... }:
    {
      programs.chromium.enable = true;
      environment.systemPackages = [ pkgs.chromium ];
    };
}
