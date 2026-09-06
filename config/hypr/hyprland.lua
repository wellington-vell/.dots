-- Hyprland Lua config - https://wiki.hypr.land

-- Monitors --
-- LG 1920x1080 primary, Samsung 1366x768 to the right
hl.monitor({
    output   = "HDMI-A-2",
    mode     = "preferred",
    position = "0x0",
    scale    = "auto",
})
hl.monitor({
    output   = "DVI-D-2",
    mode     = "preferred",
    position = "1920x0",
    scale    = "auto",
})

hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-2", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DVI-D-2", default = true })

-- Programs --
local terminal    = "ghostty"
local fileManager = "nautilus"
local menu        = "hyprlauncher"
local browser     = "zen-beta"

-- Autostart --
hl.on("hyprland.start", function ()
  hl.exec_cmd("noctalia")
end)

-- Environment --
hl.env("XCURSOR_THEME", "Yaru")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Look and Feel --
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- Misc --
hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})

-- Input --
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

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

-- Super+C/V: universal copy/paste (Ctrl+C / Shift+Insert, Ctrl+Insert in terminals)
hl.bind(mainMod .. " + C", function()
  if active_window_is_terminal() then
    send_shortcut_once("CTRL", "Insert")()
  else
    send_shortcut_once("CTRL", "C")()
  end
end)

hl.bind(mainMod .. " + V", send_shortcut_once("SHIFT", "Insert"))

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

hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
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

-- Noctalia --
local noctaliaIpc = "noctalia msg "
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

hl.window_rule({
    name  = "noctalia-settings",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size  = { 1080, 920 },
})

local noctaliaBlurRule = hl.layer_rule({
    name  = "noctalia-blur",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    no_anim     = true,
    ignore_alpha = 0.5,
    blur        = true,
    blur_popups = true,
})

-- Windows and Workspaces --
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
