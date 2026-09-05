{
  flake.modules.nixos.files =
    { pkgs, ... }:
    {
      # Matches config/hypr/hyprland.lua fileManager = "dolphin" (Super+E).
      environment.systemPackages = [ pkgs.kdePackages.dolphin ];
    };
}
