{
  flake.modules.nixos.files =
    { pkgs, ... }:
    {
      # Matches config/hypr/hyprland.lua fileManager = "nautilus" (Super+E).
      # Same file manager Omarchy ships; gvfs covers trash, USB, and network mounts.
      services.gvfs.enable = true;

      environment.systemPackages = [ pkgs.nautilus ];
    };
}
