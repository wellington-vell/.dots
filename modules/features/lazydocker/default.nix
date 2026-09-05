{
  flake.modules.nixos.lazydocker =
    { pkgs, ... }:
    let
      lazydockerIcon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/docker-desktop.svg";

      lazydockerDesktop = pkgs.makeDesktopItem {
        name = "lazydocker";
        desktopName = "LazyDocker";
        comment = "Terminal UI for Docker and Docker Compose";
        exec = "lazydocker";
        terminal = true;
        icon = "lazydocker";
        categories = [
          "Development"
          "Monitor"
        ];
        keywords = [
          "docker"
          "containers"
          "compose"
        ];
      };

      # Desktop entry + hicolor icon so launchers (noctalia) resolve Icon=lazydocker.
      lazydockerLauncher = pkgs.runCommand "lazydocker-launcher" { } ''
        mkdir -p $out/share/applications
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${lazydockerDesktop}/share/applications/lazydocker.desktop $out/share/applications/
        cp ${lazydockerIcon} $out/share/icons/hicolor/scalable/apps/lazydocker.svg
      '';
    in
    {
      virtualisation.docker.enable = true;
      users.users.well.extraGroups = [ "docker" ];

      environment.systemPackages = [
        pkgs.lazydocker
        lazydockerLauncher
      ];
    };
}
