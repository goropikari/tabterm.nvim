local Config = {}

---@class TabTerminalConfig
---@field shell string
---@field height number
---@field keymap table<string, string>
---@field setup fun(self: TabTerminalConfig, opts: TabTerminalOptions): TabTerminalConfig
---@field get_keymap fun(self: TabTerminalConfig, key: string): string

---@return TabTerminalConfig
function Config.new()
  ---@type TabTerminalConfig
  ---@diagnostic disable-next-line: missing-fields
  local obj = {
    shell = vim.o.shell or 'bash',
    height = 0.4,
    keymap = {
      toggle = '<c-t>',
      add = '<c-n>',
      move_next = '<M-n>',
      move_previous = '<M-h>',
      shutdown_current_term = '<M-w>',
    },
  }

  obj.setup = function(self, opts)
    obj.height = opts.height or obj.height
    obj.shell = opts.shell or obj.shell
    obj.keymap = vim.tbl_deep_extend('force', obj.keymap, opts.keymap or {})
    return self
  end

  obj.get_keymap = function(self, key)
    local keybind = self.keymap[key]
    assert(keybind, 'Keymap not found: ' .. key)
    return keybind
  end

  obj.set_keymap = function(self, modes, key, cb, desc)
    local keymap = self:get_keymap(key)
    vim.keymap.set(modes, keymap, cb, { desc = desc or '' })
  end

  return obj
end

return Config
