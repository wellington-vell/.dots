{
  config,
  inputs,
  ...
}:
{
  flake.modules.nixos.beta = {
    imports = [ ./_hardware-configuration.nix ];
    networking.hostName = "beta";
  };

  flake.nixosConfigurations.beta = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      beta
    ];
  };
}
