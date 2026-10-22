{
  inputs,
  ...
}:
{
  # Android phone as microphone and webcam (Phonebridge app over USB/Wi-Fi).
  # Exposes a PipeWire source "Phonebridge" and, with `phonebridge --camera`,
  # a v4l2loopback webcam on /dev/video10 that the upstream module loads.
  flake.modules.nixos.phonebridge = {
    imports = [ inputs.phonebridge.nixosModules.default ];
    programs.phonebridge.enable = true;
  };
}
