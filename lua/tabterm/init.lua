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
---@field keymap {toggle: string, add: string, move_next_tab: string, move_prev_tab: string, shutdown: string, send_visual: string, send_line: string}
local default_config = {
  shell = vim.o.shell or 'bash',
  height = 0.4,
  keymap = {
    toggle = '<c-t>',
    add = '<c-n>',
    shutdown = '<M-w>',
    move_next_tab = '<M-n>',
    move_prev_tab = '<M-h>',
    send_visual = '<leader>ss',
    send_line = '<leader>ss',
  },
}

---@type TabTermConfig
---@diagnostic disable-next-line
local config = {}

---@param key string
local function get_keymap(key)
  return config.keymap[key]
end

local function get_current_term()
  if M.state.current_term and toggleterm.get(M.state.current_term.id) then
    return M.state.current_term
  end
  return nil
end

---@param opts TabTermConfig
function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})

  vim.keymap.set({ 'n', 't' }, get_keymap('toggle'), function()
    M.toggle()
  end, { desc = 'Toggle Terminal' })
  vim.keymap.set({ 'v' }, get_keymap('send_visual'), function()
    M.send_visual_text()
  end, { desc = 'Send Visual Text to Terminal' })
  vim.keymap.set({ 'n' }, get_keymap('send_line'), function()
    M.send_line_text()
  end, { desc = 'Send Current Line to Terminal' })
end

---@return boolean
local function is_win_open()
  ---@diagnostic disable-next-line
  return M.state.winid and vim.api.nvim_win_is_valid(M.state.winid)
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
  return vim.fn.join(texts, '\n')
end

function M.send_line_text()
  local term = get_current_term()
  if term == nil then
    term = M.new_terminal()
    M.open()
  end
  local line = vim.api.nvim_get_current_line()

  term:send(line)
end

function M.send_visual_text()
  local term = get_current_term()
  if term == nil then
    term = M.new_terminal()
    M.open()
  end
  local text = get_visual_text()

  term:send(text)
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
  local terms = M.get_all_terms()
  for i, term in ipairs(terms) do
    winbar_text = winbar_text .. string.format(winbar_text_format, term.id, term_name(term, term.id == M.state.current_term.id))
    if i < #terms then
      winbar_text = winbar_text .. ' | '
    end
  end

  vim.api.nvim_set_option_value('winbar', winbar_text, { win = M.state.winid })
end

local function show_help()
  local help_content = {
    'TabTerm Help',
    '',
    'Keymaps (Normal Mode in Terminal):',
    '  ' .. get_keymap('toggle') .. ' : Toggle terminal window',
    '  ' .. get_keymap('add') .. ' : Add a new terminal tab',
    '  ' .. get_keymap('shutdown') .. ' : Close the current terminal tab',
    '  ' .. get_keymap('move_next_tab') .. ' : Move to the next terminal tab',
    '  ' .. get_keymap('move_prev_tab') .. ' : Move to the previous terminal tab',
    '  ? : Show this help',
    '',
    'Keymaps (Normal/Visual Mode in other buffers):',
    '  ' .. get_keymap('send_line') .. ' : Send current line/selection to terminal',
    '',
    'Press "q" or move to another window to close.',
  }

  local width = 0
  for _, line in ipairs(help_content) do
    if vim.fn.strwidth(line) > width then
      width = vim.fn.strwidth(line)
    end
  end
  width = width + 4 -- padding

  local height = #help_content + 2 -- padding

  local win_width = vim.api.nvim_get_option_value('columns', {})
  local win_height = vim.api.nvim_get_option_value('lines', {})

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_content)

  local help_win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'single',
  })

  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'help', { buf = buf })

  -- Close window with 'q'
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(help_win) then
      vim.api.nvim_win_close(help_win, true)
    end
  end, { buffer = buf, silent = true })

  -- Close on leaving the window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(help_win) then
        vim.api.nvim_win_close(help_win, true)
      end
    end,
  })
end

local function set_add_terminal_keymap(term)
  local bufnr = term.bufnr
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.keymap.set({ 'n', 't' }, get_keymap('add'), function()
      M.new_terminal()
    end, { buffer = bufnr, desc = 'Add Terminal' })
    vim.keymap.set({ 'n', 't' }, get_keymap('move_next_tab'), function()
      M.move_next_tab()
    end, { buffer = bufnr, desc = 'Move to Next Terminal' })
    vim.keymap.set({ 'n', 't' }, get_keymap('move_prev_tab'), function()
      M.move_prev_tab()
    end, { buffer = bufnr, desc = 'Move to Previous Terminal' })
    vim.keymap.set({ 'n' }, get_keymap('shutdown'), function()
      M.shutdown_term(term)
    end, { buffer = bufnr, desc = 'Shutdown Terminal' })
    vim.keymap.set({ 'n' }, '?', function()
      show_help()
    end, { buffer = bufnr, desc = 'Show Help' })
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

function M.get_all_terms()
  return toggleterm.get_all()
end

local function num_terms()
  return #M.get_all_terms()
end

local function index_of_term(term)
  local terms = M.get_all_terms()
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
    open_term = M.get_all_terms()[1]
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

  local terms = M.get_all_terms()
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

  local terms = M.get_all_terms()
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
    open_term = M.get_all_terms()[index + 1]
  else
    open_term = M.get_all_terms()[index - 1]
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

-- ctrl-d でターミナルが閉じられても、他にターミナルがあればそっちに切り替えるようにする。
-- この処理を入れないと window が閉じられてしまう
vim.api.nvim_create_autocmd('TermClose', {
  pattern = toggleterm_pattern,
  callback = function(args)
    if num_terms() == 1 then
      return
    end

    local close_term = nil
    for _, term in ipairs(M.get_all_terms()) do
      if term.bufnr == args.buf then
        close_term = term
        break
      end
    end

    local open_term = next_open_term(close_term)
    set_current_term(open_term)
    vim.schedule(function()
      update_winbar()
    end)
  end,
})

return M
