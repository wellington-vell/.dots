{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        wget
        git
        opencode
        pi-coding-agent
        # Build toolchains
        nodejs
        bun
        go
        rustc
        cargo
      ];

      # Per-user toolchain bin dirs (cargo install, bun add --global, go install)
      environment.sessionVariables.PATH = [
        "$HOME/.cargo/bin"
        "$HOME/.bun/bin"
        "$HOME/go/bin"
      ];
    };
}
