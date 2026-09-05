{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.steam.enable = true;
      programs.lutris.enable = true;

      environment.systemPackages = with pkgs; [
        syncplay
        qbittorrent
      ];
    };
}