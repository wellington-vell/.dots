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
          # React Developer Tools
          # https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi
          "fmkadmapgofadopljbjfkapdkoienihi"
        ];
      };
      environment.systemPackages = [ pkgs.chromium ];
    };
}
