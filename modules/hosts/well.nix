{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.well = {
    networking.hostName = "well";
  };

  flake.nixosConfigurations.well = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      desktop
      nvidia
      well
    ];
  };
}
