{
  inputs,
  ...
}:
{
  flake.modules.nixos.zen =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          extraPolicies = {
            # The wrapper discards the unwrapped package's base policies, so
            # re-register System Trust here (see zen-browser-flake example
            # 03-policies-package-override.nix) or `security.pki.*` anchors
            # won't reach Zen.
            SecurityDevices = {
              "System Trust" = "${pkgs.p11-kit}/lib/pkcs11/p11-kit-trust.so";
            };
            # NVIDIA + Wayland: Firefox defaults are conservative here and can
            # fall back to software compositing / CPU video decode, which is
            # the usual cause of random stutter. Force the GPU paths on.
            Preferences =
              let
                on = {
                  Value = true;
                  Status = "default";
                };
                int = v: {
                  Value = v;
                  Status = "default";
                };
              in
              {
                "gfx.webrender.all" = on;
                "widget.dmabuf.force-enabled" = on;
                "media.ffmpeg.vaapi.enabled" = on;
                "media.hardware-video-decoding.force-enabled" = on;
                "media.rdd-ffmpeg.enabled" = on;
                # Session state is ~1.3MB compressed and serialized on the main
                # thread; the default 15s interval shows up as periodic hitches.
                "browser.sessionstore.interval" = int 60000;
                # Unload background tabs when the system runs low on memory
                # instead of letting long-lived tabs push everything into swap.
                "browser.tabs.unloadOnLowMemory" = on;
              };
            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
              };
              # "enhancerforyoutube@maximerf.addons.mozilla.org" = {
              #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
              #   installation_mode = "force_installed";
              # };
            };
          };
        })
      ];
    };
}
