{
  flake.modules.nixos.base = {
    # Console TTYs (getty). SDDM's X11 greeter ignores these LEDs and needs
    # services.displayManager.sddm.autoNumlock instead.
    systemd.services.numlock = {
      description = "Turn on NumLock at boot";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = "for tty in /dev/tty{1..6}; do setleds -D +num < \"$tty\" || true; done";
    };

    services.displayManager.sddm.autoNumlock = true;
  };
}
