local M = {
  state = 0,
}

local default_config = {
  keymap = {
    toggle = '<c-t>',
  },
}

local config = {}

local function get_keymap(key)
  local keybind = config.keymap[key] or default_config.keymap[key]
  assert(keybind, 'Keymap not found: ' .. key)
  return keybind
end

local function set_keymap(modes, key, cb, desc)
  local keymap = get_keymap(key)
  vim.keymap.set(modes, keymap, cb, { desc = desc or '' })
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})

  set_keymap({ 'n' }, 'toggle', M.toggle, 'Toggle')
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
