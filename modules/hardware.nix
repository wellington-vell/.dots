{
  flake.modules.nixos.base = {
    imports = [ /etc/nixos/hardware-configuration.nix ];

    hardware.graphics.enable = true;
    hardware.enableRedistributableFirmware = true;
  };
}
