{
  inputs,
  ...
}:
{
  flake.modules.nixos.cursor =
    { pkgs, ... }:
    let
      # 26.05 ships Cursor 3.5.x with laggy SCM commit input; unstable is past the 3.8 fix.
      # Import (not legacyPackages) so allowUnfree applies to this nixpkgs instance.
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    in
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = [ unstable.code-cursor ];
    };
}
