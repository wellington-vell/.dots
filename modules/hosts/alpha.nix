{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.alpha = {
    imports = [
      ../../hosts/alpha/hardware-configuration.nix
    ];
  };

  flake.nixosConfigurations.alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      alpha
    ];
  };
}