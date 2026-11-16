{
  flake.modules.nixos.base = {
    hardware.graphics.enable = true;
    hardware.enableRedistributableFirmware = true;

    # Compressed swap in RAM, preferred over the 4G disk partition. Paging
    # out to NVMe under memory pressure was stalling the desktop (browser freezes).
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
  };
}
