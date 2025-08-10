local plenary_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'plenary.nvim')

if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/nvim-lua/plenary.nvim', plenary_dir }):wait()
end

local toggleterm_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'toggleterm.nvim')

if vim.fn.isdirectory(toggleterm_dir) == 0 then
  vim.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/akinsho/toggleterm.nvim', toggleterm_dir }):wait()
end

vim.opt.runtimepath:append('.')
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(toggleterm_dir)
vim.cmd('set runtimepath?')
