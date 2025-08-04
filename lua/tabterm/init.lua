local toggleterm = require('toggleterm.terminal')
local Terminal = require('toggleterm.terminal').Terminal

local M = {
  state = {
    ---@type integer|nil
    winid = nil,

    ---@type Terminal
    current_term = nil,
  },
}

---@class TabTermConfig
---@field shell string
---@field height number
---@field keymap {toggle: string, add: string, move_next_tab: string, move_prev_tab: string, shutdown: string}
local default_config = {
  shell = vim.o.shell or 'bash',
  height = 0.4,
  keymap = {
    toggle = '<c-t>',
    add = '<c-n>',
    shutdown = '<M-w>',
    move_next_tab = '<M-n>',
    move_prev_tab = '<M-h>',
  },
}

---@type TabTermConfig
---@diagnostic disable-next-line
local config = {}

---@param key string
local function get_keymap(key)
  return config.keymap[key]
end

---@param opts TabTermConfig
function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})

  vim.keymap.set({ 'n', 't' }, get_keymap('toggle'), function()
    M.toggle()
  end, { desc = 'Toggle Terminal' })
end

---@return boolean
local function is_win_open()
  ---@diagnostic disable-next-line
  return M.state.winid and vim.api.nvim_win_is_valid(M.state.winid)
end

---@param term Terminal
---@param is_current boolean
---@return string
local function term_name(term, is_current)
  local name = term.display_name or ('terminal ' .. term.id)
  if is_current then
    return '* ' .. name
  else
    return name
  end
end

local function update_winbar()
  if not is_win_open() then
    return
  end

  local winbar_text_format = "%%%d@v:lua.require'tabterm'.winbar_click_handler@[%s]%%T"
  local winbar_text = ''
  local terms = toggleterm.get_all()
  for i, term in ipairs(terms) do
    winbar_text = winbar_text .. string.format(winbar_text_format, term.id, term_name(term, term.id == M.state.current_term.id))
    if i < #terms then
      winbar_text = winbar_text .. ' | '
    end
  end

  vim.api.nvim_set_option_value('winbar', winbar_text, { win = M.state.winid })
end

local function set_add_terminal_keymap(term)
  local bufnr = term.bufnr
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.keymap.set({ 'n', 't' }, get_keymap('add'), function()
      M.new_terminal()
    end, { buffer = bufnr, desc = 'Add Terminal' })
    vim.keymap.set({ 'n' }, get_keymap('move_next_tab'), function()
      M.move_next_tab()
    end, { buffer = bufnr, desc = 'Move to Next Terminal' })
    vim.keymap.set({ 'n' }, get_keymap('move_prev_tab'), function()
      M.move_prev_tab()
    end, { buffer = bufnr, desc = 'Move to Previous Terminal' })
    vim.keymap.set({ 'n' }, get_keymap('shutdown'), function()
      M.shutdown_term(term)
    end, { buffer = bufnr, desc = 'Shutdown Terminal' })
  end
end

local function new_terminal()
  local term = Terminal:new({
    cmd = config.shell,
  })
  term:spawn()
  term.display_name = 'terminal ' .. term.id
  set_add_terminal_keymap(term)
  if is_win_open() then
    update_winbar()
  end
  return term
end

M.new_terminal = new_terminal

local function num_terms()
  return #toggleterm.get_all()
end

local function index_of_term(term)
  local terms = toggleterm.get_all()
  for i, t in ipairs(terms) do
    if t.id == term.id then
      return i
    end
  end
  return nil
end

function M.open()
  if is_win_open() then
    return
  end

  if num_terms() == 0 then
    M.state.current_term = new_terminal()
  end

  local open_term = nil
  if M.state.current_term and toggleterm.get(M.state.current_term.id) then
    open_term = M.state.current_term
  else
    open_term = toggleterm.get_all()[1]
  end

  local winid = vim.api.nvim_open_win(open_term.bufnr, true, {
    split = 'below',
    height = math.floor(vim.o.lines * default_config.height),
    style = 'minimal',
  })
  vim.cmd('wincmd J')
  M.state.winid = winid

  update_winbar()
end

function M.close()
  if not is_win_open() then
    return
  end
  vim.api.nvim_win_close(M.state.winid, true)
  M.state.winid = nil
end

function M.toggle()
  if is_win_open() then
    M.close()
  else
    M.open()
  end
end

local function set_current_term(term)
  vim.api.nvim_win_set_buf(M.state.winid, term.bufnr)
  M.state.current_term = term
  update_winbar()
end

local function reset_current_term()
  M.state.current_term = nil
end

function M.move_next_tab()
  if not is_win_open() then
    return
  end

  local terms = toggleterm.get_all()
  local index = index_of_term(M.state.current_term)
  local next_index = (index + 1) % (#terms + 1)
  if next_index == 0 then
    next_index = next_index + 1
  end
  set_current_term(terms[next_index])
end

function M.move_prev_tab()
  if not is_win_open() then
    return
  end

  local terms = toggleterm.get_all()
  local index = index_of_term(M.state.current_term)
  local prev_index = (index - 1) % #terms
  if prev_index == 0 then
    prev_index = #terms
  end
  set_current_term(terms[prev_index])
end

local function next_open_term(term)
  local open_term = nil
  local index = index_of_term(term)
  if index < num_terms() then
    open_term = toggleterm.get_all()[index + 1]
  else
    open_term = toggleterm.get_all()[index - 1]
  end
  return open_term
end

local function shutdown_term(term)
  if num_terms() == 1 then
    term:shutdown()
    reset_current_term()
    return
  end

  -- 現在開いている terminal を閉じる場合は次の terminal を開く。次の terminal がない場合は一つ前の terminal を開く
  local open_term = next_open_term(term)
  set_current_term(open_term)

  term:shutdown()
end

M.shutdown_term = shutdown_term

function M.winbar_click_handler(minwid, clicks, button, mods)
  local term = toggleterm.get(minwid)
  if term == nil then
    return
  end
  if button == 'l' then
    set_current_term(term)
  end
  if button == 'm' then
    shutdown_term(term)
  end
  if button == 'r' then
    vim.ui.input({
      prompt = 'New name: ',
      default = term.display_name,
    }, function(input)
      if input and input ~= '' then
        term.display_name = input
      end
      update_winbar()
    end)
  end
  update_winbar()
end

local toggleterm_pattern = { 'term://*#toggleterm#*', 'term://*::toggleterm::*' }

vim.api.nvim_create_autocmd('TermClose', {
  pattern = toggleterm_pattern,
  callback = function(args)
    if num_terms() == 1 then
      return
    end

    local close_term = nil
    for _, term in ipairs(toggleterm.get_all()) do
      if term.bufnr == args.buf then
        close_term = term
        break
      end
    end

    local open_term = next_open_term(close_term)
    set_current_term(open_term)
    -- vim.defer_fn(function()
    --   update_winbar()
    -- end, 50)
    vim.schedule(function()
      update_winbar()
    end)
  end,
})

return M
