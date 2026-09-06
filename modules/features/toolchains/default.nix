{
  flake.modules.nixos.toolchains =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nodejs
        bun
        go
        rustc
        cargo
      ];

      environment.sessionVariables.PATH = [
        "$HOME/.cargo/bin"
        "$HOME/.bun/bin"
        "$HOME/go/bin"
      ];
    };
}
