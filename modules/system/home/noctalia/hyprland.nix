{
  flake.modules.nixos.noctalia = {
    # Hyprland integration (kept out of the shared compositor module).
    host.hyprland.extraLua = ''
      -- Noctalia --
      -- Store --config cannot be patched by Noctalia's apply.sh; load the
      -- rendered theme file directly (seeded empty until first resolve).
      do
        local path = os.getenv("HOME") .. "/.config/hypr/noctalia.lua"
        local ok, mod = pcall(dofile, path)
        if ok and type(mod) == "table" and type(mod.apply_theme) == "function" then
          mod.apply_theme()
        else
          hl.config({
            general = {
              col = {
                active_border = "rgba(7aa2f7ee)",
                inactive_border = "rgba(1a1b26aa)",
              },
            },
          })
        end
      end

      hl.on("hyprland.start", function ()
        hl.exec_cmd("noctalia")
      end)

      local mainMod = "SUPER"
      local noctaliaIpc = "noctalia msg "

      hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle clipboard"))
      hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle launcher"))
      hl.bind(mainMod .. " + CTRL + O", hl.dsp.exec_cmd(noctaliaIpc .. "panel-toggle control-center"))
      hl.bind(mainMod .. " + comma", function()
        local current = hl.get_config("general.layout") or "dwindle"
        if current == "scrolling" then
          hl.dispatch(hl.dsp.layout("swapcol l"))
        else
          hl.dispatch(hl.dsp.exec_cmd(noctaliaIpc .. "settings-toggle"))
        end
      end)
      hl.bind("ALT + Tab",           hl.dsp.exec_cmd(noctaliaIpc .. "window-switcher"))
      hl.bind("Print",               hl.dsp.exec_cmd(noctaliaIpc .. "screenshot-region"))
      hl.bind("SHIFT + Print",       hl.dsp.exec_cmd(noctaliaIpc .. "screenshot-fullscreen"))
      hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(noctaliaIpc .. "plugin noctalia/screen_recorder:service all toggle focused"))

      hl.window_rule({
          name  = "noctalia-settings",
          match = { class = "dev.noctalia.Noctalia" },
          float = true,
          size  = { 1080, 920 },
      })

      hl.layer_rule({
          name  = "noctalia-blur",
          match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
          no_anim     = true,
          ignore_alpha = 0.5,
          blur        = true,
          blur_popups = true,
      })
    '';
  };
}
