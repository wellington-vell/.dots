{
  flake.modules.nixos.capture =
    { pkgs, ... }:
    let
      noctaliaCaptureConfig = ../../../config/noctalia/90-capture.toml;
    in
    {
      # Browser / Electron screen sharing (Hyprland portal is pulled in by
      # programs.hyprland; keep GTK portal for file/app choosers).
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = [
          "hyprland"
          "gtk"
        ];
      };

      environment.systemPackages = with pkgs; [
        hyprpicker
        # Required by Noctalia's screen_recorder bar plugin
        gpu-screen-recorder
      ];

      # Link capture/recorder bar config into the user noctalia profile
      systemd.user.services.noctalia-capture-config = {
        description = "Install Noctalia capture bar config";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "noctalia-capture-config" ''
            set -euo pipefail
            mkdir -p "$HOME/.config/noctalia"
            ln -sfn ${noctaliaCaptureConfig} "$HOME/.config/noctalia/90-capture.toml"
          '';
        };
      };
    };
}
