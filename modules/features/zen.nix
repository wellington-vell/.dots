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
              in
              {
                "gfx.webrender.all" = on;
                "widget.dmabuf.force-enabled" = on;
                "media.ffmpeg.vaapi.enabled" = on;
                "media.hardware-video-decoding.force-enabled" = on;
                "media.rdd-ffmpeg.enabled" = on;
              };
            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
              };
              "enhancerforyoutube@maximerf.addons.mozilla.org" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
                installation_mode = "force_installed";
              };
            };
          };
        })
      ];
    };
}
