{
  flake.modules.nixos.terminal =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      ghosttyConfig = ../../../config/ghostty/config.ghostty;
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
