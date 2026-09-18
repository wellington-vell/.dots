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
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
        xorg.libxshmfence
      ];

      # Pull the driver from nixpkgs-unstable so the browser revisions track
      # current @playwright/test releases (your projects use 1.62.x, which
      # wants chromium_headless_shell-1234; stable 26.05 still ships 1.59.x).
      environment.systemPackages = with unstable; [
        playwright-driver
        # Includes chromium, chromium-headless-shell, firefox, webkit, ffmpeg.
        # NOTE: 1.62+ splits the headless shell out of the `chromium` target,
        # so the shell must be present — this derivation ships it.
        playwright-driver.browsers
        playwright-test
      ];

      environment.sessionVariables = {
        # Prefer the Nix-patched browsers so `bunx`/`npx playwright test`
        # works without a download. Requires the npm version
        # (@playwright/test in package.json) to match the nixpkgs
        # playwright-driver version; if they drift, either pin npm to the nix
        # version (`bun add -d @playwright/test@$(nix eval --raw nixpkgs#playwright-driver.version)`)
        # or unset this var and run:
        #   bunx playwright install chromium chromium-headless-shell
        PLAYWRIGHT_BROWSERS_PATH = "${unstable.playwright-driver.browsers}";
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
    };
}
