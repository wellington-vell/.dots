{
  flake.modules.nixos.syncplay =
    { pkgs, ... }:
    let
      syncplay-patched = pkgs.syncplay.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace syncplay/constants.py \
            --replace-fail 'VLC_PATHS = [' 'VLC_PATHS = ["vlc", "${pkgs.vlc}/bin/vlc", "/run/current-system/sw/bin/vlc",'
        '';
      });
    in
    {
      environment.systemPackages = [
        syncplay-patched
      ];
    };
}
