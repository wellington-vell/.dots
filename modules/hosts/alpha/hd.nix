{
  # Internal Seagate 1TB NTFS volume labeled "HD".
  flake.modules.nixos.alpha = {
    fileSystems."/mnt/hd" = {
      device = "/dev/disk/by-uuid/18CE48A2CE4879D0";
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "umask=022"
        "force"
        "nofail"
        "x-gvfs-show"
        "x-gvfs-name=HD"
        "x-systemd.device-timeout=10"
      ];
    };
  };
}
