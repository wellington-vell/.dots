{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.sddm.enableGnomeKeyring = true;

      environment.systemPackages = with pkgs; [
        libsecret
      ];
    };
}