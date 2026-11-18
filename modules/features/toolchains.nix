{
  inputs,
  ...
}:
{
  flake.modules.nixos.toolchains =
    { pkgs, ... }:
    let
      rust = pkgs.rust-bin.stable."1.100.0".default.override {
        extensions = [
          "cargo"
          "clippy"
          "rust-analyzer"
          "rust-src"
          "rustfmt"
        ];
      };
      bun' = pkgs.bun.overrideAttrs (
        old:
        let
          version = "1.4.0";
          newSources = old.passthru.sources // {
            "aarch64-darwin" = pkgs.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
              hash = "sha256-xmnpf2Fk4cluBwF0jbmN+ndJKQjL2DlMdVcTSnNd44E=";
            };
            "aarch64-linux" = pkgs.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
              hash = "sha256-SxozLuhhmD65O8/m93D/+U4+MbLDiL2uo8jtNeWO7Q4=";
            };
            "x86_64-linux" = pkgs.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
              hash = "sha256-GE+0WV8NQBohfPfHjBvEMLqDMU2reouUgFurv3+nCX8=";
            };
          };
        in
        {
          inherit version;
          src =
            newSources.${pkgs.stdenv.hostPlatform.system}
              or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
          passthru = old.passthru // {
            sources = newSources;
          };
        }
      );
    in
    {
      nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

      environment.systemPackages = with pkgs; [
        nodejs
        bun'
        go
        rust
        python3
        uv
        just
        # Required by the Rust `clang` crate (https://docs.rs/clang/latest/clang/)
        # via `clang-sys`: needs `libclang.so` at build/run time.
        clang
        libclang
      ];

      environment.sessionVariables = {
        PATH = [
          "$HOME/.cargo/bin"
          "$HOME/.bun/bin"
          "$HOME/go/bin"
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
    };
}
