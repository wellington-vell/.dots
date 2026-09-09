{
  flake.modules.nixos.qbittorrent =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.qbittorrent ];
    };
}
