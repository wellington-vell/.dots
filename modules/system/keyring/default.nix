{
  flake.modules.nixos.keyring =
    { pkgs, ... }:
    let
      defaultKeyringTemplate = pkgs.writeText "Default_keyring.keyring" ''
        [keyring]
        display-name=Default keyring
        ctime=0
        mtime=0
        lock-on-idle=false
        lock-after=false
      '';

      # Unlocked default keyring — avoids login unlock prompts
      ensureDefaultKeyring = pkgs.writeShellScript "ensure-default-keyring" ''
        set -euo pipefail
        KEYRING_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/keyrings"
        KEYRING_FILE="$KEYRING_DIR/Default_keyring.keyring"
        DEFAULT_FILE="$KEYRING_DIR/default"
        LOGIN_FILE="$KEYRING_DIR/login.keyring"

        mkdir -p "$KEYRING_DIR"

        if [[ ! -f $KEYRING_FILE ]]; then
          sed "s/^ctime=0$/ctime=$(date +%s)/" ${defaultKeyringTemplate} > "$KEYRING_FILE"
        fi

        # Always prefer the unlocked default over the encrypted "login" keyring
        printf 'Default_keyring\n' > "$DEFAULT_FILE"

        # Encrypted login.keyring triggers password prompts when PAM unlock
        # fails (e.g. empty login password). Move it aside once.
        if [[ -f $LOGIN_FILE && ! -f $LOGIN_FILE.bak ]]; then
          mv "$LOGIN_FILE" "$LOGIN_FILE.bak"
        fi

        chmod 700 "$KEYRING_DIR"
        chmod 600 "$KEYRING_FILE" 2>/dev/null || true
        chmod 644 "$DEFAULT_FILE"
      '';
    in
    {
      services.gnome.gnome-keyring.enable = true;

      # Unlock via PAM at graphical login (SDDM)
      security.pam.services = {
        login.enableGnomeKeyring = true;
        sddm.enableGnomeKeyring = true;
        sddm-autologin.enableGnomeKeyring = true;
      };

      environment.systemPackages = with pkgs; [
        libsecret
        gnome-keyring
      ];

      systemd.user.services.ensure-default-keyring = {
        description = "Ensure unlocked default GNOME keyring";
        wantedBy = [ "graphical-session-pre.target" ];
        before = [ "graphical-session-pre.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ensureDefaultKeyring;
        };
      };
    };
}
