# tabterm.nvim

A Neovim plugin that extends [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) to provide a **tab-like terminal management experience** using `winbar`.

![image](./doc/image.png)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "goropikari/tabterm.nvim",
  dependencies = { "akinsho/toggleterm.nvim" },
  opts = {
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
  },
}
```
