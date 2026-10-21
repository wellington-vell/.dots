{
  flake.modules.nixos.nvidia = {
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

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
      # VA-API hardware video decode via nvidia-vaapi-driver (Firefox/Zen)
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };
  };
}
