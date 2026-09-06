{
  flake.modules.nixos.capture =
    { pkgs, ... }:
    let
      noctaliaCaptureConfig = ../../../config/noctalia/90-capture.toml;

      noctaliaRecordToggle = pkgs.writeShellScriptBin "noctalia-record-toggle" ''
        # Toggle the Noctalia screen recorder and confirm the transition with a
        # toast (the screen_recorder plugin itself only toasts on errors/saves).
        set -uo pipefail

        count_gsr() {
          pgrep -f "[g]pu-screen-recorder -w" | wc -l
        }

        before=$(count_gsr)
        noctalia msg plugin noctalia/screen_recorder:service all toggle

        after=$before
        for _ in $(seq 1 25); do
          sleep 0.2
          after=$(count_gsr)
          [ "$after" != "$before" ] && break
        done

        if [ "$after" -gt "$before" ]; then
          noctalia msg notification-show "Recording started" "Pick a screen in the portal dialog if prompted"
        elif [ "$after" -lt "$before" ]; then
          noctalia msg notification-show "Recording stopped" "Saved to ~/Videos/Recordings"
        fi
      '';
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
        noctaliaRecordToggle
        procps
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
