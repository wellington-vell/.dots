{
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    let
      identity = import "${inputs.identity}/identity.nix";
    in
    {
      programs.git = {
        enable = true;
        config = {
          user.name = identity.gitUserName;
          user.email = identity.gitUserEmail;

          # Authenticate over HTTPS via GitHub CLI (run `gh auth login` once).
          "credential \"https://github.com\"" = {
            helper = "!${pkgs.gh}/bin/gh auth git-credential";
          };
        };
      };

      environment.systemPackages = [ pkgs.gh ];
    };
}
