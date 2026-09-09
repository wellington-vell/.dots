{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
      fonts.fontconfig.defaultFonts.sansSerif = [ "JetBrainsMono Nerd Font" ];
    };
}
