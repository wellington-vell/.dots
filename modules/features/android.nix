{
  inputs,
  ...
}:
{
  # Toolchain for building the Phonebridge Android app (Rust Android targets,
  # Android SDK/NDK, JDK, cargo-tauri). The dev shell's inputs are part of the
  # system closure, so garbage collection never deletes them and
  # `nix develop ./app` in the phonebridge checkout starts without downloading.
  flake.modules.nixos.android =
    { pkgs, ... }:
    {
      system.extraDependencies = [
        inputs.phonebridge-app.devShells.${pkgs.stdenv.hostPlatform.system}.default.inputDerivation
      ];
      # adb outside the dev shell, to install and debug the app.
      environment.systemPackages = [ pkgs.android-tools ];
    };
}
