local Terminal = require('toggleterm.terminal').Terminal
local Config = require('tabterm.config')

State = {}

local function new_terminal()
  local term = Terminal:new({
    cmd = 'bash',
  })
  term:spawn()
  term.display_name = 'terminal ' .. term.id
  return term
end

---@class TabTerminalState
---@field winid number|nil
---@field config TabTerminalConfig
---@field current_term Terminal|nil
---@field terms Terminal[]
---@field is_win_open fun(self: TabTerminalState): boolean
---@field open_win fun(self: TabTerminalState)
---@field close_win fun(self: TabTerminalState)
---@field _get_terms fun(self: TabTerminalState): Terminal[]
---@field add_term fun(self: TabTerminalState)
---@field move_next fun(self: TabTerminalState)
---@field move_previous fun(self: TabTerminalState)
---@field update_winbar fun(self: TabTerminalState)
---@field is_valid fun(self: TabTerminalState): boolean
---@field show fun(self: TabTerminalState)

---@param cfg TabTerminalConfig
function State.new(cfg)
  local init_term = new_terminal()

  ---@type TabTerminalState
  ---@diagnostic disable-next-line: missing-fields
  local obj = {
    winid = nil,
    config = cfg or Config.new(),
    current_term = init_term,
    terms = { init_term },
  }

  obj.is_win_open = function(self)
    return self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid)
  end

  obj.open_win = function(self)
    local height = 0.4
    if self:is_win_open() then
      return
    end
    local bufnr = self.current_term.bufnr
    self.winid = vim.api.nvim_open_win(bufnr, true, {
      split = 'below',
      height = math.floor(vim.o.lines * height),
      style = 'minimal',
    })
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

  obj.add_term = function(self)
    local terms = self:_get_terms()
    local term = new_terminal()
    table.insert(terms, term)
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

  obj.is_valid = function(self)
    local bufnr = self.current_term and self.current_term.bufnr
    bufnr = bufnr or -1
    return vim.api.nvim_buf_is_valid(bufnr)
  end

  obj.update_winbar = function(self)
    if not self:is_win_open() then
      return
    end
    local terms = self:_get_terms()
    local winbar_txt = ''
    for i, term in ipairs(terms) do
      local prefix = self.current_term.bufnr == term.bufnr and '*' or ''
      winbar_txt = winbar_txt .. prefix .. term.display_name
      if i < #terms then
        winbar_txt = winbar_txt .. ' | '
      end
    end
    vim.api.nvim_set_option_value('winbar', winbar_txt, { win = self.winid })
  end

  obj.show = function(self)
    vim.print(self)
  end

  return obj
end

return State
