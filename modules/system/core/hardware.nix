{
  flake.modules.nixos.base = {
    hardware.graphics.enable = true;
    hardware.enableRedistributableFirmware = true;
  };
}
