vim.cmd('set runtimepath?')

local Config = require('tabterm.config')

describe('Config', function()
  local config

  before_each(function()
    config = Config.new()
  end)

  it('should have default values', function()
    assert.are.equal(vim.o.shell or 'bash', config.shell)
    assert.are.equal(0.4, config.height)
    assert.are.same({
      toggle = '<c-t>',
      add = '<c-n>',
      move_next = '<M-n>',
      move_previous = '<M-h>',
      shutdown_current_term = '<M-w>',
      send_visual = '<leader>ss',
      send_line = '<leader>ss',
    }, config.keymap)
  end)

  it('should setup with new values', function()
    local opts = {
      height = 0.6,
      shell = 'zsh',
      keymap = {
        toggle = '<c-s>',
      },
    }
    config:setup(opts)

    assert.are.equal(0.6, config.height)
    assert.are.equal('zsh', config.shell)
    assert.are.equal('<c-s>', config.keymap.toggle)
  end)

  it('should get keymap', function()
    assert.are.equal('<c-t>', config:get_keymap('toggle'))
  end)

  it('should throw error for non-existent keymap', function()
    assert.has_error(function()
      config:get_keymap('non_existent_key')
    end, 'Keymap not found: non_existent_key')
  end)
end)
