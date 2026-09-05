{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

      hardware.graphics.enable = true;

      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = true;
        open = false;
      };
    };
}