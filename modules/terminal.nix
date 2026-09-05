{
  flake.modules.nixos.terminal =
    { pkgs, ... }:
    {
      documentation.man.enable = true;

      environment.systemPackages = with pkgs; [
        ghostty
        tldr
        man-pages
        man-pages-posix
      ];
    };
}
