{
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { ... }:
    let
      identity = import "${inputs.identity}/identity.nix";
    in
    {
      programs.git = {
        enable = true;
        config = {
          user.name = identity.gitUserName;
          user.email = identity.gitUserEmail;
        };
      };
    };
}
