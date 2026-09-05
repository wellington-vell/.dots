{
  config,
  ...
}:
{
  flake.modules.nixos.desktop = {
    imports = with config.flake.modules.nixos; [
      hyprland
      noctalia
      firefox
      discord
      gaming
      editors
      terminal
      tmux
      lazydocker
      keyring
      cursor
      capture
    ];
  };
}
