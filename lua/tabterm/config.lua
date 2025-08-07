local Config = {}

---@class TabTerminalConfig
---@field keymap table<string, string>
---@field setup fun(self: TabTerminalConfig, opts: table<string, string>): TabTerminalConfig
---@field get_keymap fun(self: TabTerminalConfig, key: string): string
---@field set_keymap fun(self: TabTerminalConfig, modes: string | string[], key: string, cb: fun(), desc?: string)

---@return TabTerminalConfig
function Config.new()
  ---@type TabTerminalConfig
  ---@diagnostic disable-next-line: missing-fields
  local obj = {
    keymap = {
      toggle = '<c-t>',
      add = '<c-n>',
      move_next = '<M-n>',
      move_previous = '<M-h>',
    },
  }

  obj.setup = function(self, opts)
    self.keymap = vim.tbl_deep_extend('force', self.keymap, opts or {})
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
