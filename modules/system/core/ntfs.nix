{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      boot.supportedFilesystems = [
        "ntfs"
        "ntfs-3g"
        "ntfs3"
      ];
      environment.systemPackages = [ pkgs.ntfs3g ];
    };
}
