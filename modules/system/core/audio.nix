{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;

        # Motherboard audio is unused (no mic, no optical out); disabling the
        # card drops its analog input and IEC958 sink (and that sink's monitor)
        # so only Phonebridge shows up as a capture device.
        wireplumber.extraConfig."51-disable-onboard-audio" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "alsa_card.pci-0000_0a_00.6"; } ];
              actions.update-props."device.disabled" = true;
            }
          ];
        };
      };

      environment.systemPackages = with pkgs; [
        pavucontrol
        playerctl
      ];
    };
}
