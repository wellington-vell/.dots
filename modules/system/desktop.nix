{
  config,
  ...
}:
{
  flake.modules.nixos.desktop = {
    imports = with config.flake.modules.nixos; [
      # Desktop / CLI stack (modules/system/)
      hyprland
      sddm
      portal
      keyring
      fonts
      pointer
      filemanager
      terminal
      tmux
      # Apps / tools (modules/features/)
      chromium
      zen
      obsidian
      discord
      gaming
      syncplay
      qbittorrent
      neovim
      vscode
      cursor
      lazydocker
      vlc
      toolchains
      agents
    ];
  };
}
