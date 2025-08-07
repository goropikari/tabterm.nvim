local State = require('tabterm.state')

local M = {
  state = {},
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
  M.new_state()
end

function M.set_state(state)
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.state[tabnr] = state
end

function M.get_current_state()
  local tabnr = vim.api.nvim_get_current_tabpage()
  return M.state[tabnr]
end

function M.is_valid_state(state)
  return state ~= nil and state:is_valid()
end

function M.new_state()
  local state = State.new()
  M.set_state(state)
  return state
end

function M.toggle()
  local state = M.get_current_state()
  if not M.is_valid_state(state) then
    state = M.new_state()
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
