{
  flake.modules.nixos.gaming =
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
