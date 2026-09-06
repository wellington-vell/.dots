{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.alpha = {
    imports = [ ./_hardware-configuration.nix ];
    networking.hostName = "alpha";
  };

  flake.nixosConfigurations.alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      desktop
      nvidia
      alpha
    ];
  };
}
