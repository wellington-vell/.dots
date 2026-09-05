{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.mutableUsers = true;
      users.users.well = {
        isNormalUser = true;
        initialHashedPassword = "";
        extraGroups = [ "wheel" ];
        packages = with pkgs; [ tree ];
      };
    };
}