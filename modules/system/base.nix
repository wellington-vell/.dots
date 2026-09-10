{
  flake.modules.nixos.base =
    { pkgs, config, ... }:
    {
      system.stateVersion = config.system.nixos.release;

      environment.systemPackages = with pkgs; [
        wget
        git
        nil
        nixfmt
      ];
    };
}
