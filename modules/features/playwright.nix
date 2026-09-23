{
  inputs,
  ...
}:
{
  flake.modules.nixos.playwright =
    { pkgs, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
      };
    in
    {
      # Downloaded browsers from `playwright install` (npm/bun) are
      # dynamically linked against /lib64 + system libs. nix-ld makes them
      # runnable on NixOS; without it you get "Executable doesn't exist" or
      # launch failures even after a successful install.
      programs.nix-ld.enable = true;
      programs.nix-ld.libraries = with pkgs; [
        alsa-lib
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libdrm
        libgbm
        libGL
        libuuid
        libxkbcommon
        mesa
        nspr
        nss
        pango
        systemd
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        libxshmfence
      ];

      environment.systemPackages = with unstable; [
        playwright-driver
        playwright-test
      ];

      environment.sessionVariables = {
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
    };
}
