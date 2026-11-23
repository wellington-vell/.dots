{
  # Internal Seagate 1TB data volume, ext4, labeled "hd".
  flake.modules.nixos.alpha = {
    fileSystems."/mnt/hd" = {
      device = "/dev/disk/by-label/hd";
      fsType = "ext4";
      options = [
        "defaults"
        "nofail"
        "x-gvfs-show"
        "x-gvfs-name=HD"
        "x-systemd.device-timeout=10"
      ];
    };
  };
}
