{
  flake.modules.nixos.hyprland =
    { config, ... }:
    let
      apps = config.host.apps;
    in
    {
      host.hyprland.fragments.binds = ''
        -- Programs --
        local terminal    = "${apps.terminal}"
        local fileManager = "${apps.fileManager}"
        local menu        = "${apps.menu}"
        local browser     = "${apps.browser}"

        -- Keybindings --
        local mainMod = "SUPER"

        hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
        hl.bind(mainMod .. " + W", hl.dsp.window.close())

        local function send_shortcut_once(mods, key)
          return function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
            hl.timer(function()
              hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
            end, { timeout = 50, type = "oneshot" })
          end
        end

        local function active_window_is_terminal()
          local window = hl.get_active_window()
          if not window then
            return false
          end
          local class = (window.class or window.initial_class or ""):lower()
          return class:find("ghostty", 1, true)
            or class:find("kitty", 1, true)
            or class:find("alacritty", 1, true)
            or class:find("foot", 1, true)
            or class:find("com.mitchellh.ghostty", 1, true)
        end

        -- Super+C/V: universal copy/paste.
        -- Ghostty maps Shift+Insert to primary selection (not clipboard), so GitHub's
        -- copy button (clipboard-only) would paste nothing. Use Ctrl+Shift+V instead.
        hl.bind(mainMod .. " + C", function()
          if active_window_is_terminal() then
            send_shortcut_once("CTRL", "Insert")()
          else
            send_shortcut_once("CTRL", "C")()
          end
        end)

        hl.bind(mainMod .. " + V", function()
          if active_window_is_terminal() then
            send_shortcut_once("CTRL + SHIFT", "V")()
          else
            send_shortcut_once("CTRL", "V")()
          end
        end)

        hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
        hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
        hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
        hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
        hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

        hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
        hl.bind(mainMod .. " + CTRL + F",  hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
        hl.bind(mainMod .. " + ALT + F",   hl.dsp.window.fullscreen({ mode = "maximized" }))
        hl.bind(mainMod .. " + O", function()
          hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
          hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
        end)
        hl.bind(mainMod .. " + L", function()
          local current = hl.get_config("general.layout") or "dwindle"
          local target  = current == "dwindle" and "scrolling" or "dwindle"
          hl.config({ general = { layout = target } })
        end)

        -- Scrolling layout controls
        hl.bind(mainMod .. " + period",          hl.dsp.layout("move +col"))
        hl.bind(mainMod .. " + semicolon",       hl.dsp.layout("swapcol r"))
        hl.bind(mainMod .. " + SHIFT + period",  hl.dsp.layout("colresize +conf"))
        hl.bind(mainMod .. " + SHIFT + comma",   hl.dsp.layout("colresize -conf"))

        hl.bind(mainMod .. " + ALT + Return", hl.dsp.exec_cmd(terminal .. " -e tmux"))
        hl.bind(mainMod .. " + SHIFT + B",    hl.dsp.exec_cmd(browser))
        hl.bind(mainMod .. " + SHIFT + D",    hl.dsp.exec_cmd(terminal .. " -e lazydocker"))
        hl.bind(mainMod .. " + SHIFT + N",    hl.dsp.exec_cmd(terminal .. " -e nvim"))

        hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"))

        hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
        hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
        hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
        hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

        for i = 1, 10 do
            local key = i % 10
            hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
            hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
        end

        hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
        hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

        hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
      '';
    };
}
