local Terminal = require('toggleterm.terminal').Terminal
local Config = require('tabterm.config')

State = {}

---@class TabTerminalState
---@field winid number|nil
---@field config TabTerminalConfig
---@field current_term Terminal|nil
---@field terms Terminal[]
---@field init fun(self: TabTerminalState): TabTerminalState
---@field is_win_open fun(self: TabTerminalState): boolean
---@field _get_current_term fun(self: TabTerminalState): Terminal
---@field open_win fun(self: TabTerminalState)
---@field close_win fun(self: TabTerminalState)
---@field _get_terms fun(self: TabTerminalState): Terminal[]
---@field _set_keymap fun(self: TabTerminalState, bufnr: number)
---@field _new_terminal fun(self: TabTerminalState): Terminal
---@field add_term fun(self: TabTerminalState)
---@field get_term fun(self: TabTerminalState, term_id: number): Terminal|nil
---@field set_term fun(self: TabTerminalState, term_id: number)
---@field rename_term fun(self: TabTerminalState, term_id: number)
---@field shutdown_term fun(self: TabTerminalState, term_id: number)
---@field shutdown_current_term fun(self: TabTerminalState)
---@field move_next fun(self: TabTerminalState)
---@field move_previous fun(self: TabTerminalState)
---@field update_winbar fun(self: TabTerminalState)
---@field term_name fun(self: TabTerminalState, term: Terminal, is_current: boolean): string
---@field show fun(self: TabTerminalState)

---@param cfg TabTerminalConfig
function State.new(cfg)
  ---@type TabTerminalState
  ---@diagnostic disable-next-line: missing-fields
  local obj = {
    winid = nil,
    config = cfg or Config.new(),
    current_term = nil,
    terms = {},
  }

  obj.init = function(self)
    local term = self:_new_terminal()
    self.winid = nil
    self.current_term = term
    self.terms = { term }
    return self
  end

  obj.is_win_open = function(self)
    return self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid)
  end

  obj._get_current_term = function(self)
    local current_term = self.current_term
    if current_term and vim.api.nvim_buf_is_valid(current_term.bufnr) then
      return current_term
    end
    local terms = self:_get_terms()
    if #terms == 0 then
      current_term = self:_new_terminal()
      self.current_term = current_term
      self.terms = { current_term }
    else
      current_term = terms[1]
      self.current_term = current_term
    end
    return self.current_term
  end

  obj.open_win = function(self)
    if self:is_win_open() then
      return
    end
    local bufnr = self:_get_current_term().bufnr
    self.winid = vim.api.nvim_open_win(bufnr, true, {
      split = 'below',
      style = 'minimal',
    })
    vim.cmd('wincmd J')
    local height = math.floor(vim.o.lines * self.config.height)
    vim.api.nvim_win_set_height(self.winid, height)
    obj:update_winbar()
  end

  obj.close_win = function(self)
    if not self:is_win_open() then
      return
    end
    vim.api.nvim_win_close(self.winid, true)
  end

  obj._get_terms = function(self)
    local terms = {}
    for _, term in ipairs(self.terms) do
      if vim.api.nvim_buf_is_valid(term.bufnr) then
        table.insert(terms, term)
      end
    end
    self.terms = terms
    return terms
  end

  local function set_keymap(bufnr, modes, key, cb, desc)
    local keymap = obj.config:get_keymap(key)
    vim.keymap.set(modes, keymap, cb, { buffer = bufnr, desc = desc or '' })
  end

  obj._set_keymap = function(self, bufnr)
    set_keymap(bufnr, { 'n', 't' }, 'add', function()
      self:add_term()
    end, 'Add Terminal')
    set_keymap(bufnr, { 'n', 't' }, 'move_next', function()
      self:move_next()
    end, 'Move Next Terminal')
    set_keymap(bufnr, { 'n', 't' }, 'move_previous', function()
      self:move_previous()
    end, 'Move Previous Terminal')
    set_keymap(bufnr, { 'n' }, 'shutdown_current_term', function()
      self:shutdown_current_term()
    end, 'Shutdown Current Terminal')
  end

  obj._new_terminal = function(self)
    local term = Terminal:new({
      cmd = self.config.shell,
    })
    term:spawn()
    term.display_name = 'terminal ' .. term.id
    self:_set_keymap(term.bufnr)
    return term
  end

  obj.add_term = function(self)
    local terms = self:_get_terms()
    local term = self:_new_terminal()
    table.insert(terms, term)
    self:update_winbar()
  end

  obj.set_term = function(self, term_id)
    local term = self:get_term(term_id)
    if not term then
      return
    end
    self.current_term = term
    vim.api.nvim_set_current_buf(term.bufnr)
    self:update_winbar()
  end

  obj.get_term = function(self, term_id)
    local terms = self:_get_terms()
    for _, term in ipairs(terms) do
      if term.id == term_id then
        return term
      end
    end
    return nil
  end

  obj.shutdown_term = function(self, term_id)
    local term = self:get_term(term_id)
    if not term then
      return
    end

    -- 現在のターミナルを閉じるときは次のターミナルに移動する。
    if term.bufnr == self.current_term.bufnr then
      self:move_next()
    end

    term:shutdown()
    self:update_winbar()
  end

  obj.shutdown_current_term = function(self)
    local current_term = self.current_term
    if current_term == nil or not vim.api.nvim_buf_is_valid(current_term.bufnr) then
      return
    end
    local terms = self:_get_terms()
    if #terms == 1 then
      -- FIXME: すべてのターミナルを閉じる -> 新しいターミナルを開く -> ターミナルを閉じると何故か window の focus が terminal の window とは別のところになってしまう。
      -- ターミナルを追加する操作を入れておくと focus が terminal window のままになる。
      self:add_term()
    end
    self:move_next()

    current_term:shutdown()
    self:update_winbar()
  end

  obj.rename_term = function(self, term_id)
    local term = self:get_term(term_id)
    if not term then
      return
    end

    local new_name = vim.fn.input('New name for terminal ' .. term_id .. ': ', term.display_name or '')
    if new_name ~= '' then
      term.display_name = new_name
      self:update_winbar()
    end
  end

  obj.move_next = function(self)
    if not self:is_win_open() then
      return
    end

    local current_index = 0
    local terms = self:_get_terms()
    for i, term in ipairs(terms) do
      if term.bufnr == self.current_term.bufnr then
        current_index = i
        break
      end
    end
    local next_index = (current_index + 1) % (#terms + 1)
    if next_index == 0 then
      next_index = 1
    end
    local term = terms[next_index]
    self.current_term = term
    vim.api.nvim_set_current_buf(term.bufnr)
    self:update_winbar()
  end

  obj.move_previous = function(self)
    if not self:is_win_open() then
      return
    end

    local current_index = 0
    local terms = self:_get_terms()
    for i, term in ipairs(terms) do
      if term.bufnr == self.current_term.bufnr then
        current_index = i
        break
      end
    end
    local prev_index = current_index - 1
    if prev_index == 0 then
      prev_index = #terms
    end
    local term = terms[prev_index]
    self.current_term = term
    vim.api.nvim_set_current_buf(term.bufnr)
    self:update_winbar()
  end

  obj.term_name = function(self, term, is_current)
    local name = term.display_name or ('terminal ' .. term.id)
    if is_current then
      return '* ' .. name
    else
      return name
    end
  end

  obj.update_winbar = function(self)
    if not self:is_win_open() then
      return
    end

    local current_term = self:_get_current_term()
    local winbar_text_format = "%%%d@v:lua.require'tabterm'.winbar_click_handler@[%s]%%T"
    local winbar_text = ''
    local terms = self:_get_terms()
    for i, term in ipairs(terms) do
      winbar_text = winbar_text .. string.format(winbar_text_format, term.id, self:term_name(term, term.id == current_term.id))
      if i < #terms then
        winbar_text = winbar_text .. ' | '
      end
    end

    vim.api.nvim_set_option_value('winbar', winbar_text, { win = self.winid })
  end

  obj.show = function(self)
    vim.print(self)
  end

  return obj:init()
end

return State
