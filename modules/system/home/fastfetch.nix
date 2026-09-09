{
  flake.modules.nixos.base =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # JSONC config for fastfetch — uses the built-in NixOS ASCII avatar.
      fastfetchConfig = pkgs.writeText "fastfetch-config.jsonc" ''
        {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          "logo": {
            "source": "NixOS",
            "padding": {
              "top": 1,
              "right": 2
            }
          },
          "display": {
            "separator": " ",
            "brightColor": true,
            "key": {
              "width": 24
            }
          },
          "modules": [
            "title",
            "separator",
            "os",
            "host",
            "kernel",
            "uptime",
            "packages",
            "shell",
            "display",
            "de",
            "wm",
            "wmtheme",
            "theme",
            "icons",
            "font",
            "cursor",
            "terminal",
            "terminalfont",
            "cpu",
            "gpu",
            "memory",
            "swap",
            "disk",
            "battery",
            "locale",
            "break",
            "colors"
          ]
        }
      '';

      # Image avatar variant (PNG snowflake via nixos-icons).
      fastfetchImageConfig = pkgs.writeText "fastfetch-image.jsonc" ''
        {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          "logo": {
            "type": "kitty",
            "source": "${pkgs.nixos-icons}/share/icons/hicolor/512x512/apps/nix-snowflake.png",
            "width": 22,
            "height": 11,
            "padding": {
              "top": 1,
              "right": 2
            }
          },
          "display": {
            "separator": ": ",
            "brightColor": true,
            "key": {
              "width": 14
            }
          },
          "modules": [
            "title",
            "separator",
            "os",
            "host",
            "kernel",
            "uptime",
            "packages",
            "shell",
            "display",
            "de",
            "wm",
            "wmtheme",
            "theme",
            "icons",
            "font",
            "cursor",
            "terminal",
            "terminalfont",
            "cpu",
            "gpu",
            "memory",
            "swap",
            "disk",
            "battery",
            "locale",
            "break",
            "colors"
          ]
        }
      '';

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      environment.systemPackages = with pkgs; [
        fastfetch
        chafa
        nixos-icons
      ];

      environment.etc."xdg/fastfetch/config.jsonc".source = fastfetchConfig;
      environment.etc."xdg/fastfetch/config-image.jsonc".source = fastfetchImageConfig;

      system.activationScripts.fastfetchConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/fastfetch"
          ln -sfn ${fastfetchConfig} "$home/.config/fastfetch/config.jsonc"
        done
      '';
    };
}
