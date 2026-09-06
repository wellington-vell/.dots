{
  flake.modules.nixos.terminal =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      ghosttyConfig = pkgs.writeText "config.ghostty" ''
        # ble.sh + starship already own the prompt. Ghostty's bash inject emits
        # OSC 133 "fresh line" on every prompt, which shows up as a blank/duplicate
        # line on open (Cursor/VSCode terminals don't use this inject).
        shell-integration = none

        confirm-close-surface = false
        window-padding-x = 14
        window-padding-y = 14
        resize-overlay = never
        cursor-style = block
        cursor-style-blink = false
      '';
      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      documentation.man.enable = true;

      environment.systemPackages = with pkgs; [
        ghostty
        tldr
        man-pages
        man-pages-posix
      ];

      # Ghostty only reads $XDG_CONFIG_HOME/ghostty/config.ghostty (not /etc/xdg).
      system.activationScripts.ghosttyConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/ghostty"
          ln -sfn ${ghosttyConfig} "$home/.config/ghostty/config.ghostty"
        done
      '';
    };
}
