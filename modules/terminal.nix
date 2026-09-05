{
  flake.modules.nixos.base =
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