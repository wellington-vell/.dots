{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.beta = {
    networking.hostName = "beta";
  };

  flake.nixosConfigurations.beta = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      beta
    ];
  };
}
