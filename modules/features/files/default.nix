{
  flake.modules.nixos.files =
    { pkgs, ... }:
    {
      # Matches config/hypr/hyprland.lua fileManager = "nautilus" (Super+E).
      # Same file manager Omarchy ships; gvfs covers trash, USB, and network mounts.
      services.gvfs.enable = true;

      # Nautilus resolves its sidebar/toolbar symbolic icons (starred,
      # user-trash, ...) from the icon theme. GTK defaults to "Adwaita",
      # which isn't in the system path otherwise, so icons render missing.
      environment.systemPackages = [
        pkgs.nautilus
        pkgs.adwaita-icon-theme
      ];
    };
}
