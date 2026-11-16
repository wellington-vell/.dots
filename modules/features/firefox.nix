{
  flake.modules.nixos.firefox = {
    programs.firefox = {
      enable = true;
      # NVIDIA + Wayland: Firefox defaults are conservative here and can
      # fall back to software compositing / CPU video decode, which is
      # the usual cause of random stutter. Force the GPU paths on.
      preferences = {
        "gfx.webrender.all" = true;
        "widget.dmabuf.force-enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        # Session state is serialized on the main thread; the default 15s
        # interval shows up as periodic hitches.
        "browser.sessionstore.interval" = 60000;
        # Unload background tabs when the system runs low on memory
        # instead of letting long-lived tabs push everything into swap.
        "browser.tabs.unloadOnLowMemory" = true;
      };
      policies.ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
