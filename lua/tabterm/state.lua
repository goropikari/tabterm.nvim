State = {}

function State.new()
  local obj = {
    winid = 0,
  }

  obj.is_win_open = function()
    return obj.winid ~= 0
  end

  obj.open_win = function(self)
    if self.is_win_open() then
      return
    end
    print('open')
    obj.winid = 1
  end

  obj.close_win = function(self)
    if not self.is_win_open() then
      return
    end
    print('close')
    obj.winid = 0
  end

  return obj
end

return State
