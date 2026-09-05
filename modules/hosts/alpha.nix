{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.alpha = {
    networking.hostName = "alpha";
  };

  flake.nixosConfigurations.alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      alpha
    ];
  };
}
