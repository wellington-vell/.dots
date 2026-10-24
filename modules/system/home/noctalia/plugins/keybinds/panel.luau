--!nonstrict
-- Keybinds cheat sheet panel. Sections and rows come from keybinds.json:
--   [{ section, glyph, items = [{ keys, label, details }] }]
-- Sections start collapsed (click the header to open). Each row shows the shortcut
-- chip + a short label; clicking toggles a details line.
--
-- Keyboard (capture_keys in plugin.toml): j/k move the cursor over the visible
-- section headers and rows, l expands, h collapses (or jumps to the parent
-- section), g jumps to the top, q closes.
--
-- Noctalia 5.0.1 (plugin API 30) can't scroll a child into view, so only one
-- section is open at a time and it renders a WINDOW-row slice that follows the
-- cursor, with clickable "N more" markers for the hidden rows.

local WINDOW = 11

local sections = {}
local loadError = nil
local expanded = {}
local closeButton = true

-- Cursor: id of the focused node ("s1" header, "s1:i3" row). `visible` is the flat,
-- ordered list of focusable ids (all rows of the open section, hidden by the window
-- or not), used for j/k movement. `windowStart` is the open section's first shown row.
local cursor = "s1"
local visible = {}
local windowStart = 1

local function load()
  local raw, err = noctalia.readFile("keybinds.json")
  if not raw then
    loadError = `Could not read keybinds.json: {err}`
    sections = {}
    return
  end
  local data, decodeErr = noctalia.json.decode(raw)
  if type(data) ~= "table" then
    loadError = `Invalid keybinds.json: {decodeErr}`
    sections = {}
    return
  end
  loadError = nil
  sections = data
end

local render

local function toggle(id)
  cursor = id
  local opening = not expanded[id]
  if opening and not string.find(id, ":", 1, true) then
    -- Accordion: opening a section closes the others (and their rows).
    expanded = {}
    windowStart = 1
  end
  expanded[id] = opening
  render()
end

local function moreMarker(key, text, target)
  return ui.row({
    key = key,
    paddingH = 8,
    paddingV = 4,
    justify = "center",
    onClick = function()
      cursor = target
      render()
    end,
  }, {
    ui.label({ text = text, color = "on_surface_variant" }),
  })
end

local function itemRow(id, item)
  local open = expanded[id] == true
  local focused = cursor == id
  local children = {
    ui.row({ key = id .. ":head", gap = 12, align = "center" }, {
      ui.row({
        key = id .. ":chip",
        width = 230,
        paddingH = 10,
        paddingV = 4,
        radius = 6,
        fill = "surface_variant",
        align = "center",
      }, {
        ui.label({ text = item.keys or "", fontWeight = "semibold", color = "primary", maxLines = 1 }),
      }),
      ui.label({ text = item.label or "", color = "on_surface", flexGrow = 1, maxLines = 1 }),
      ui.glyph({
        name = open and "chevron-up" or "chevron-down",
        size = 14,
        color = "on_surface_variant",
      }),
    }),
  }
  if open and item.details and item.details ~= "" then
    table.insert(children, ui.label({
      key = id .. ":details",
      text = item.details,
      color = "on_surface_variant",
      maxWidth = 540,
    }))
  end
  return ui.column({
    key = id,
    gap = 6,
    paddingH = 8,
    paddingV = 6,
    radius = 8,
    border = "primary",
    borderWidth = focused and 1 or 0,
    align = "stretch",
    onClick = function()
      toggle(id)
    end,
  }, children)
end

local function sectionHeader(id, section, count)
  local open = expanded[id] == true
  return ui.row({
    key = id .. ":title",
    gap = 8,
    align = "center",
    paddingH = 8,
    paddingV = 8,
    radius = 8,
    fill = "surface_variant",
    border = "primary",
    borderWidth = cursor == id and 1 or 0,
    onClick = function()
      toggle(id)
    end,
  }, {
    ui.glyph({ name = section.glyph or "keyboard", size = 16, color = "secondary" }),
    ui.label({ text = section.section or "", fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
    ui.label({ text = tostring(count), color = "on_surface_variant" }),
    ui.glyph({ name = open and "chevron-up" or "chevron-down", size = 14, color = "on_surface_variant" }),
  })
end

render = function()
  local header = {
    ui.glyph({ name = "keyboard", size = 18, color = "primary" }),
    ui.label({ text = "Keybinds", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
    ui.label({ text = "j/k move · l open · h close", color = "on_surface_variant" }),
  }
  if closeButton then
    table.insert(header, ui.button({ glyph = "close", onClick = "onCloseClicked" }))
  end

  visible = {}
  local body = {}
  if loadError then
    table.insert(body, ui.label({ text = loadError, color = "error" }))
  end
  for si, section in ipairs(sections) do
    local id = `s{si}`
    local items = section.items or {}
    table.insert(visible, id)
    local rows = { sectionHeader(id, section, #items) }
    if expanded[id] then
      for ii = 1, #items do
        table.insert(visible, `{id}:i{ii}`)
      end
      -- Slide the window so the cursor row stays inside it.
      local cur = tonumber(string.match(cursor, "^" .. id .. ":i(%d+)$"))
      if cur then
        if cur < windowStart then
          windowStart = cur
        elseif cur > windowStart + WINDOW - 1 then
          windowStart = cur - WINDOW + 1
        end
      end
      windowStart = math.clamp(windowStart, 1, math.max(1, #items - WINDOW + 1))
      local last = math.min(#items, windowStart + WINDOW - 1)
      if windowStart > 1 then
        table.insert(rows, moreMarker(id .. ":up", `▲ {windowStart - 1} more`, `{id}:i{windowStart - 1}`))
      end
      for ii = windowStart, last do
        table.insert(rows, itemRow(`{id}:i{ii}`, items[ii]))
      end
      if last < #items then
        table.insert(rows, moreMarker(id .. ":down", `▼ {#items - last} more`, `{id}:i{last + 1}`))
      end
    end
    table.insert(body, ui.column({ key = id, gap = 2, align = "stretch" }, rows))
  end

  panel.render(ui.column({ flexGrow = 1, gap = 16, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, header),
    ui.scroll({ flexGrow = 1, gap = 8, align = "stretch" }, body),
  }))
end

local function indexOf(id)
  for i, v in ipairs(visible) do
    if v == id then
      return i
    end
  end
  return 1
end

local function move(delta)
  if #visible == 0 then
    return
  end
  local i = math.clamp(indexOf(cursor) + delta, 1, #visible)
  cursor = visible[i]
  render()
end

local function sectionOf(id)
  return string.match(id, "^(s%d+)")
end

function onKey(chord, pressed)
  if pressed == false or pressed == "false" then
    return
  end
  if chord == "j" then
    move(1)
  elseif chord == "k" then
    move(-1)
  elseif chord == "l" then
    if not expanded[cursor] then
      toggle(cursor)
    elseif not string.find(cursor, ":", 1, true) then
      move(1) -- already-open section: step into its first row
    end
  elseif chord == "h" then
    if expanded[cursor] then
      toggle(cursor)
    elseif string.find(cursor, ":", 1, true) then
      local parent = sectionOf(cursor)
      expanded[parent] = false
      cursor = parent
      render()
    end
  elseif chord == "g" then
    cursor = visible[1] or "s1"
    render()
  elseif chord == "q" then
    panel.close()
  end
end

function onOpen(_context)
  expanded = {}
  cursor = "s1"
  windowStart = 1
  closeButton = noctalia.getSetting("shell.show_close_buttons") ~= false
  load()
  render()
end

function onCloseClicked()
  panel.close()
end
