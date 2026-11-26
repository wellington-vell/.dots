{
  flake.modules.nixos.opensnitch =
    { pkgs, ... }:
    {
      services.opensnitch = {
        enable = true;
        # Upstream defaults to "deny", which blocks every outbound connection
        # until the GUI is running and rules are added. Start permissive so
        # enabling the module never breaks networking; tighten via the UI or
        # by flipping this to "deny" once rules exist.
        settings.DefaultAction = "allow";
      };

      # GUI (tray + rules editor). Launch from the launcher; it ships a desktop entry.
      environment.systemPackages = [ pkgs.opensnitch-ui ];
    };
}
