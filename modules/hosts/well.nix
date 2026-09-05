{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.well = {
    imports = [
      ../../hosts/well/hardware-configuration.nix
    ];
  };

  flake.nixosConfigurations.well = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      well
    ];
  };
}