{
  # BCM43569 USB Wi-Fi (0a5c:0bdc) misreports its USB 3 config descriptor length,
  # hiding the TX endpoint from brcmfmac. This module corrects it.
  flake.modules.nixos.bcm43569-usb3 =
    { config, pkgs, ... }:
    let
      kernel = config.boot.kernelPackages.kernel;
      quirk = pkgs.stdenv.mkDerivation {
        pname = "bcm43569-usb3";
        version = "0-unstable-2026-10-02-${kernel.version}";

        src = pkgs.fetchFromGitHub {
          owner = "ADCDS";
          repo = "bcm43569-usb3-linux";
          rev = "0a34c80c17b27f39a2ea151aca2bc6b650f5915e";
          hash = "sha256-DJpJWRoG4UPne/xzk5xIDdD2uKpcqv0Bb6SfxiDfxCc=";
        };
        sourceRoot = "source/usb_quirk";

        hardeningDisable = [ "pic" ];
        nativeBuildInputs = kernel.moduleBuildDependencies;
        makeFlags = config.boot.kernelPackages.kernelModuleMakeFlags ++ [
          "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        ];

        installPhase = ''
          runHook preInstall
          install -Dm444 bcm43569_config_quirk.ko \
            -t $out/lib/modules/${kernel.modDirVersion}/extra
          runHook postInstall
        '';

        meta.license = pkgs.lib.licenses.gpl2Only;
      };
    in
    {
      boot.extraModulePackages = [ quirk ];
      boot.kernelModules = [ "bcm43569_config_quirk" ];
      # Must be active before brcmfmac uploads firmware and the chip re-enumerates.
      boot.extraModprobeConfig = "softdep brcmfmac pre: bcm43569_config_quirk";

      # Defaults for new profiles (e.g. made by Noctalia). The 2015 firmware is
      # only known to connect with PMF off and the permanent MAC.
      networking.networkmanager.settings = {
        "connection-bcm43569" = {
          match-device = "interface-name:wlan0";
          "wifi-sec.pmf" = 1;
          "wifi.cloned-mac-address" = "permanent";
        };
        "device-bcm43569" = {
          match-device = "interface-name:wlan0";
          "wifi.scan-rand-mac-address" = "no";
        };
      };

      # After a warm reboot the stick is already running firmware (0bdc), so
      # brcmfmac attaches during its own init and deadlocks waiting for
      # brcmfmac_wcc, which needs brcmfmac loaded. Load both while the stick is
      # deauthorized, then let it probe.
      boot.blacklistedKernelModules = [ "brcmfmac" ];
      systemd.services.bcm43569-wifi = {
        description = "Load BCM43569 USB Wi-Fi driver";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        before = [ "NetworkManager.service" ];
        restartIfChanged = false;
        path = [ pkgs.kmod ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = 30;
        };
        script = ''
          devs=()
          for d in /sys/bus/usb/devices/*; do
            [ -e "$d/idVendor" ] || continue
            id="$(cat "$d/idVendor"):$(cat "$d/idProduct")"
            if [ "$id" = 0a5c:0bdc ]; then
              devs+=("$d")
              echo 0 > "$d/authorized"
            fi
          done

          status=0
          modprobe brcmfmac && modprobe brcmfmac_wcc || status=$?

          for d in "''${devs[@]}"; do
            echo 1 > "$d/authorized" || status=1
          done
          exit "$status"
        '';
      };
    };
}
