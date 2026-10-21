{
  inputs,
  ...
}:
{
  # Claude Desktop isn't in nixpkgs; community flake repackages the official
  # Windows build for Linux. FHS variant so MCP servers (npx, uvx, …) run.
  flake.modules.nixos.claude-desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
      ];
    };
}
