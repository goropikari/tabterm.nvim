local M = {
  state = 0,
}

local default_config = {}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.is_open()
  return M.state == 1
end

function M.open()
  if M.is_open() then
    return
  end
  print('open')
  M.state = 1
end

function M.close()
  if not M.is_open() then
    return
  end
  print('close')
  M.state = 0
end

return M
