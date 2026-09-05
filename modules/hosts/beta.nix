{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.beta = {
    imports = [
      ../../hosts/beta/hardware-configuration.nix
    ];
  };

  flake.nixosConfigurations.beta = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      beta
    ];
  };
}