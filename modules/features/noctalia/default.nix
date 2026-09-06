{
  inputs,
  ...
}:
{
  flake.modules.nixos.noctalia =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      noctaliaConfig = ../../../config/noctalia/config.toml;
      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      imports = [ inputs.noctalia.nixosModules.default ];

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };

      # Noctalia only reads config from ~/.config/noctalia/, so symlink the
      # repo-managed config.toml there (same pattern as the ghostty config).
      system.activationScripts.noctaliaConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/noctalia"
          ln -sfn ${noctaliaConfig} "$home/.config/noctalia/config.toml"
        done
      '';
    };
}
