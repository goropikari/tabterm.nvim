local M = {}

local default_config = {}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
end

return M
