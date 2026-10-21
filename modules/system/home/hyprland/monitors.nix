{
  flake.modules.nixos.hyprland =
    { lib, config, ... }:
    let
      monitorLua = lib.concatMapStrings (
        m:
        let
          hyprMode = if m.mode == "preferred" then "preferred" else m.mode;
        in
        ''
          hl.monitor({
              output   = "${m.output}",
              mode     = "${hyprMode}",
              position = "${m.position}",
              scale    = "${m.scale}",
          })
        ''
      ) config.host.monitors;

      workspaceLua = lib.concatMapStrings (
        m:
        let
          ids = lib.unique (lib.optional (m.defaultWorkspace != null) m.defaultWorkspace ++ m.workspaces);
        in
        lib.concatMapStrings (
          ws:
          let
            isDefault = ws == m.defaultWorkspace;
          in
          ''
            hl.workspace_rule({ workspace = "${toString ws}", monitor = "${m.output}"${lib.optionalString isDefault ", default = true"} })
          ''
        ) ids
      ) config.host.monitors;
    in
    {
      host.hyprland.fragments.monitors =
        if config.host.monitors == [ ] then
          ''
            -- Hyprland Lua config - https://wiki.hypr.land

            -- Monitors --
            -- (none configured; Hyprland auto layout)
          ''
        else
          ''
            -- Hyprland Lua config - https://wiki.hypr.land

            -- Monitors --
            ${monitorLua}
            ${workspaceLua}
          '';
    };
}
