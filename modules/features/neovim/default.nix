{
  flake.modules.nixos.neovim =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # LazyVim logomark (from LazyVim/lazyvim.github.io static/img/icon.svg).
      lazyvimIcon = ../../../config/lazyvim/lazyvim.svg;

      # The neovim wrapper ships its .desktop as "Neovim wrapper"; shadow it
      # with a properly named + iconed entry in the user's local applications dir
      # (which takes precedence over the system entry).
      lazyvimDesktop = pkgs.makeDesktopItem {
        name = "lazynvim";
        desktopName = "LazyVim";
        genericName = "Text Editor";
        comment = "Neovim configured with LazyVim";
        exec = "nvim %F";
        terminal = true;
        icon = "lazyvim-app";
        type = "Application";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        mimeTypes = [
          "text/plain"
          "text/x-makefile"
          "text/x-c"
          "text/x-c++"
          "application/x-shellscript"
        ];
      };

      # Ships the themed lazyvim icon so launchers resolve Icon=lazyvim-app.
      lazyvimIconTheme = pkgs.runCommand "lazyvim-icon-theme" { } ''
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${lazyvimIcon} $out/share/icons/hicolor/scalable/apps/lazyvim-app.svg
      '';

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      environment.sessionVariables.EDITOR = "nvim";
      environment.sessionVariables.VISUAL = "nvim";

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      # LazyVim starter from config/nvim — plugins install to ~/.local/share/nvim,
      # and lazy.nvim writes lazy-lock.json / lazyvim.json at the config root, so
      # the user's ~/.config/nvim stays a real writable dir. Wire the read-only
      # config entries (init.lua, lua/, stylua.toml) into it from the store.
      system.activationScripts.lazyvimConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/nvim"
          ln -sfn ${../../../config/nvim}/init.lua "$home/.config/nvim/init.lua"
          ln -sfn ${../../../config/nvim}/stylua.toml "$home/.config/nvim/stylua.toml"
          rm -rf "$home/.config/nvim/lua"
          ln -sfn ${../../../config/nvim}/lua "$home/.config/nvim/lua"
        done
      '';

      # Shadow the neovim wrapper's "Neovim wrapper" launcher entry with a
      # LazyVim-named one in each user's local applications dir.
      system.activationScripts.lazyvimDesktop = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.local/share/applications"
          ln -sfn ${lazyvimDesktop}/share/applications/lazynvim.desktop "$home/.local/share/applications/nvim.desktop"
        done
      '';

      environment.systemPackages = with pkgs; [
        lazyvimIconTheme
        gcc
        unzip
        wget
        curl
        tree-sitter
      ];
    };
}
