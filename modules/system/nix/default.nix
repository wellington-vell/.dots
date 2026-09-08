{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        let
          name = lib.getName pkg;
        in
        builtins.elem name [
          "cursor"
          "discord"
          "nvidia-settings"
          "nvidia-x11"
          "obsidian"
          "steam"
          "steam-unwrapped"
          "vscode"
        ]
        # nvidia kernel modules have the distinct pname
        # "nvidia-kernel-modules" / "nvidia-open" (see pkgs/os-specific/linux/nvidia-x11/kernel-modules.nix:17)
        || lib.hasPrefix "nvidia-" name;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
}
