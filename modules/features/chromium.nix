{
  flake.modules.nixos.chromium =
    { pkgs, ... }:
    {
      programs.chromium = {
        enable = true;
        extensions = [
          # Mobile View
          # https://chromewebstore.google.com/detail/mobile-view-%E2%80%94-mobile-simu/hocbjiaeeijekejepphjihbpogikmofh
          "hocbjiaeeijekejepphjihbpogikmofh"
        ];
      };
      environment.systemPackages = [ pkgs.chromium ];
    };
}
