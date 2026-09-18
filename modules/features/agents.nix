{
  inputs,
  ...
}:
{
  flake.modules.nixos.agents =
    { pkgs, lib, ... }:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "cursor-cli" ];
      };
      # Upstream install script links both `agent` (primary) and `cursor-agent`
      # (legacy) to the same binary; nixpkgs only ships `cursor-agent`.
      agentAlias = pkgs.runCommand "cursor-agent-alias" { } ''
        mkdir -p $out/bin
        ln -s ${lib.getExe unstable.cursor-cli} $out/bin/agent
      '';
    in
    {
      environment.systemPackages = [
        unstable.opencode
        pkgs.pi-coding-agent
        unstable.cursor-cli
        agentAlias
      ];
    };
}
