local State = require('tabterm.state')
local Config = require('tabterm.config')

local M = {
  state = {},
  config = nil,
}

---@class TabTerminalOptions
---@field keymap table<string, string>

local function set_keymap(modes, key, cb, desc)
  local keymap = M.config:get_keymap(key)
  vim.keymap.set(modes, keymap, cb, { desc = desc or '' })
end

---@param opts TabTerminalOptions|nil
function M.setup(opts)
  M.config = Config.new():setup(opts or {})

  set_keymap({ 'n', 't' }, 'toggle', M.toggle, 'Toggle')
  set_keymap({ 'n', 't' }, 'add', M.add_term, 'Add Terminal')
  set_keymap({ 'n', 't' }, 'move_next', M.move_next, 'Move Next Terminal')
  set_keymap({ 'n', 't' }, 'move_previous', M.move_previous, 'Move Previous Terminal')
  M.new_state()
end

---@param state TabTerminalState
function M.set_state(state)
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.state[tabnr] = state
end

---@return TabTerminalState
function M.get_current_state()
  local tabnr = vim.api.nvim_get_current_tabpage()
  return M.state[tabnr]
end

---@return boolean
function M.is_valid_state(state)
  return state ~= nil and state:is_valid()
end

---@return TabTerminalState
function M.new_state()
  local state = State.new(M.config)
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

function M.add_term()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  state:add_term()
  state:update_winbar()
end

function M.move_next()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  state:move_next()
end

function M.move_previous()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  state:move_previous()
end

function M.show()
  M.get_current_state():show()
end

return M
