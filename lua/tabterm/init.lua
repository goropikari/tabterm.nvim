local State = require('tabterm.state')
local Config = require('tabterm.config')

local M = {
  state = {},
  config = nil,
}

---@class TabTerminalOptions
---@field shell string
---@field height number
---@field keymap table<string, string>

local function set_keymap(modes, key, cb, desc)
  local keymap = M.config:get_keymap(key)
  vim.keymap.set(modes, keymap, cb, { desc = desc or '' })
end

---@param opts TabTerminalOptions|nil
function M.setup(opts)
  M.config = Config.new():setup(opts or {})

  set_keymap({ 'n', 't' }, 'toggle', M.toggle, 'Toggle')
  set_keymap({ 'n' }, 'send_line', M.send_line_text, 'Send Line Text')
  set_keymap({ 'v' }, 'send_visual', M.send_visual_selection, 'Send Visual Selection')
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
  return state ~= nil
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

function M.set_term_at_index(index)
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  state:set_term_at_index(index)
end

function M.shutdown_current_term()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  state:shutdown_current_term()
end

local function get_visual_lines(opts)
  if vim.fn.mode() == 'n' then -- command から使う用
    return vim.fn.getline(opts.line1, opts.line2)
  else -- <leader> key を使った keymap 用
    local lines = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = vim.fn.mode() })
    -- https://github.com/neovim/neovim/discussions/26092
    vim.cmd([[ execute "normal! \<ESC>" ]])
    return lines
  end
end

local function get_visual_text(opts)
  local texts = get_visual_lines(opts or {})
  return vim.fn.join(texts, '\n') ---@diagnostic disable-line
end

function M.send_line_text()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  local line = vim.api.nvim_get_current_line()

  state:_get_current_term():send(line)
end

function M.send_visual_selection()
  local state = M.get_current_state()
  assert(M.is_valid_state(state))
  local text = get_visual_text()
  state:_get_current_term():send(text)
end

function M.show()
  M.get_current_state():show()
end

---@diagnostic disable-next-line: unused-local
function M.winbar_click_handler(term_id, clicks, button, mods)
  local state = M.get_current_state()
  if term_id == nil then
    return
  end
  if button == 'l' then
    state:set_term(term_id)
  end
  if button == 'm' then
    state:shutdown_term(term_id)
  end
  if button == 'r' then
    state:rename_term(term_id)
  end
end

local function mouse_drag_cb(term_id)
  local state = M.get_current_state()
  local terms = state:_get_terms()
  local current_index = 0
  for i, term in ipairs(terms) do
    if term.bufnr == state.current_term.bufnr then
      current_index = i
      break
    end
  end
  -- 現在の位置からのドラッグ距離に応じて次のタブを選択
  local next_index = math.min(current_index + 1, #terms)
  state:set_term_at_index(next_index)
end

local function set_drag_keymap(bufnr, cfg)
  local drag_map = cfg:get_keymap('drag')
  if not drag_map then
    return
  end
  vim.keymap.set({ 'n', 't' }, drag_map, mouse_drag_cb, { buffer = bufnr })
end

return M
