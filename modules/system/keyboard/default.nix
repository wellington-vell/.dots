{
  flake.modules.nixos.base = {
    systemd.services.numlock = {
      description = "Turn on NumLock at boot";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = "for tty in /dev/tty{1..6}; do setleds -D +num < \"$tty\" || true; done";
    };
  };
}