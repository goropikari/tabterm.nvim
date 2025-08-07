local State = require('tabterm.state')

local M = {
  state = nil,
}

local default_config = {
  keymap = {
    toggle = '<c-t>',
  },
}

local config = {}

local function get_keymap(key)
  local keybind = config.keymap[key] or default_config.keymap[key]
  assert(keybind, 'Keymap not found: ' .. key)
  return keybind
end

local function set_keymap(modes, key, cb, desc)
  local keymap = get_keymap(key)
  vim.keymap.set(modes, keymap, cb, { desc = desc or '' })
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})

  set_keymap({ 'n' }, 'toggle', M.toggle, 'Toggle')
  M.state = State.new()
end

function M.get_current_state()
  return M.state
end

local function is_valid_state(state)
  return state ~= nil and state:is_valid()
end

local function new_state()
  M.state = State.new()
  return M.state
end

function M.toggle()
  local state = M.get_current_state()
  if not is_valid_state(state) then
    state = new_state()
  end
  if state:is_win_open() then
    state:close_win()
  else
    state:open_win()
  end
end

function M.show()
  M.get_current_state():show()
end

return M
