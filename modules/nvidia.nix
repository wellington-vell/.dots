{
  flake.modules.nixos.nvidia = {
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

    hardware.cpu.amd.updateMicrocode = true;

    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement.enable = true;
      open = false;
    };

    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
