{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.mutableUsers = true;
      users.users.well = {
        isNormalUser = true;
        initialHashedPassword = "";
        # Literal store path (package form becomes /run/current-system/sw/bin/bash).
        shell = "${pkgs.bashInteractive}/bin/bash";
        # video/render: DRM device access for gpu-screen-recorder monitor enum.
        extraGroups = [
          "wheel"
          "video"
          "render"
        ];
        packages = with pkgs; [ tree ];
      };
    };
}
