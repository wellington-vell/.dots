{
  flake.modules.nixos.lazydocker =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lazydocker
        (pkgs.makeDesktopItem {
          name = "lazydocker";
          desktopName = "LazyDocker";
          comment = "Terminal UI for Docker and Docker Compose";
          exec = "lazydocker";
          terminal = true;
          icon = "docker";
          categories = [
            "Development"
            "Monitor"
          ];
          keywords = [
            "docker"
            "containers"
            "compose"
          ];
        })
      ];
    };
}
