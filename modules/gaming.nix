{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.steam.enable = true;

      environment.systemPackages = with pkgs; [
        lutris
        syncplay
        qbittorrent
      ];
    };
}