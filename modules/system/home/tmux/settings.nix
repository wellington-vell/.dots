{
  flake.modules.nixos.tmux = {
    programs.tmux = {
      enable = true;
      keyMode = "vi";
      terminal = "tmux-256color";
      baseIndex = 1;
      historyLimit = 50000;
      escapeTime = 10;
      aggressiveResize = true;

      extraConfig = ''
        # General
        set -ag terminal-overrides ",*:RGB"
        set -g mouse on
        set -g renumber-windows on
        set -g focus-events on
        set -g set-clipboard on
        set -g allow-passthrough on
        set -g detach-on-destroy off
        set -g extended-keys on
        set -g extended-keys-format csi-u
        set -ag terminal-features "xterm-kitty:extkeys"
        set -as terminal-features ",*:clipboard"
      '';
    };
  };
}
