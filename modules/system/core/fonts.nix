{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        liberation_ttf
        noto-fonts
        noto-fonts-color-emoji
      ];

      fonts.fontconfig = {
        defaultFonts = {
          monospace = [ "JetBrainsMono Nerd Font" ];
          sansSerif = [ "Liberation Sans" ];
          serif = [ "Liberation Serif" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
}
