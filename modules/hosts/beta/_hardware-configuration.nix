{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ ];
  boot.kernelModules = [ ];
  fileSystems."/" = {
    device = "nodev";
    fsType = "tmpfs";
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
