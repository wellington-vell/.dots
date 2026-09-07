{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.mutableUsers = true;
      users.users.well = {
        isNormalUser = true;
        initialHashedPassword = "";
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
