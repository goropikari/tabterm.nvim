State = {}

function State.new()
  local bufnr = vim.api.nvim_create_buf(false, true)

  local obj = {
    winid = nil,
    bufnr = bufnr,
  }

  obj.is_win_open = function(self)
    return self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid)
  end

  local height = 0.4
  obj.open_win = function(self)
    if self:is_win_open() then
      return
    end
    self.winid = vim.api.nvim_open_win(self.bufnr, true, {
      split = 'below',
      height = math.floor(vim.o.lines * height),
      style = 'minimal',
    })
    vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, { 'This is a tab terminal buffer ' .. bufnr })
  end

  obj.close_win = function(self)
    if not self:is_win_open() then
      return
    end
    vim.api.nvim_win_close(self.winid, true)
  end

  obj.is_valid = function(self)
    return self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr)
  end

  obj.show = function(self)
    vim.print(self)
  end

  return obj
end

return State
