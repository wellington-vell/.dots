{
  flake.modules.nixos.alpha = {
    host.dotsPath = "/home/well/.dots";

    # LG 1920x1080 primary, Samsung 1366x768 to the right
    host.monitors = [
      {
        output = "HDMI-A-2";
        mode = "1920x1080";
        position = "0x0";
        primary = true;
        defaultWorkspace = 1;
      }
      {
        output = "DVI-D-2";
        mode = "1366x768";
        position = "1920x0";
        defaultWorkspace = 2;
      }
    ];

    # host.locale = "en_US.UTF-8";
    # host.timeZone = "America/Sao_Paulo";
    # host.apps.browser = "zen-beta";
  };
}
