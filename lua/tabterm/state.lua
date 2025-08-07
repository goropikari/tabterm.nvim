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
---@field current_term Terminal|nil
---@field config TabTerminalConfig
---@field is_win_open fun(self: TabTerminalState): boolean
---@field open_win fun(self: TabTerminalState)
---@field close_win fun(self: TabTerminalState)
---@field is_valid fun(self: TabTerminalState): boolean
---@field show fun(self: TabTerminalState)

---@param cfg TabTerminalConfig
function State.new(cfg)
  local term = new_terminal()

  ---@type TabTerminalState
  ---@diagnostic disable-next-line: missing-fields
  local obj = {
    winid = nil,
    current_term = term,
    config = cfg or Config.new(),
  }

  obj.is_win_open = function(self)
    return self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid)
  end

  local height = 0.4
  obj.open_win = function(self)
    if self:is_win_open() then
      return
    end
    local bufnr = self.current_term.bufnr
    self.winid = vim.api.nvim_open_win(bufnr, true, {
      split = 'below',
      height = math.floor(vim.o.lines * height),
      style = 'minimal',
    })
  end

  obj.close_win = function(self)
    if not self:is_win_open() then
      return
    end
    vim.api.nvim_win_close(self.winid, true)
  end

  obj.is_valid = function(self)
    local bufnr = self.current_term and self.current_term.bufnr
    bufnr = bufnr or -1
    return vim.api.nvim_buf_is_valid(bufnr)
  end

  obj.show = function(self)
    vim.print(self)
  end

  return obj
end

return State
