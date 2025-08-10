local Config = require('tabterm.config')

describe('tabterm.state', function()
  local State
  local config

  before_each(function()
    -- Reset the module to ensure clean state for each test
    package.loaded['tabterm.state'] = nil
    State = require('tabterm.state')
    config = Config.new()
  end)

  it('should initialize with one terminal', function()
    local state = State.new(config)
    assert.are.same(1, #state:_get_terms())
    assert.is_not_nil(state.current_term)
    assert.are.same(state.terms[1], state.current_term)
  end)

  it('should add a new terminal', function()
    local state = State.new(config)
    assert.are.same(1, #state:_get_terms())

    state:add_term()
    assert.are.same(2, #state:_get_terms())
  end)

  it('should get a terminal by its id', function()
    local state = State.new(config)
    local first_term = state.current_term
    local term = state:get_term(first_term.id)

    assert.are.same(first_term, term)
    assert.is_nil(state:get_term(9999))
  end)

  it('should set the current terminal', function()
    local state = State.new(config)
    state:add_term()
    local second_term = state:_get_terms()[2]

    -- open_win is needed to set a buffer for set_term
    state:open_win()
    state:set_term(second_term.id)

    assert.are.same(second_term, state.current_term)
    state:close_win()
  end)

  it('should shutdown a terminal', function()
    local state = State.new(config)
    state:add_term()
    local terms = state:_get_terms()
    local first_term_id = terms[1].id
    local second_term_id = terms[2].id
    assert.are.same(2, #terms)

    state:shutdown_term(first_term_id)
    local remaining_terms = state:_get_terms()
    assert.are.same(1, #remaining_terms)
    assert.are.same(second_term_id, remaining_terms[1].id)
  end)

  describe('navigation', function()
    local state

    before_each(function()
      state = State.new(config)
      state:add_term() -- term 2
      state:add_term() -- term 3
      assert.are.same(3, #state:_get_terms())
      state:open_win()
    end)

    after_each(function()
      state:close_win()
    end)

    it('should move to the next terminal', function()
      local terms = state:_get_terms()
      local term1 = terms[1]
      local term2 = terms[2]
      local term3 = terms[3]

      assert.are.same(term1, state.current_term)

      state:move_next()
      assert.are.same(term2, state.current_term)

      state:move_next()
      assert.are.same(term3, state.current_term)

      -- should wrap around
      state:move_next()
      assert.are.same(term1, state.current_term)
    end)

    it('should move to the previous terminal', function()
      local terms = state:_get_terms()
      local term1 = terms[1]
      local term2 = terms[2]
      local term3 = terms[3]

      assert.are.same(term1, state.current_term)

      state:move_previous()
      assert.are.same(term3, state.current_term)

      state:move_previous()
      assert.are.same(term2, state.current_term)
    end)
  end)

  it('should format term name correctly', function()
    local state = State.new(config)
    local term = state.current_term
    term.display_name = 'MyTerm'

    local current_name = state:term_name(term, true)
    assert.are.same('* MyTerm', current_name)

    local other_name = state:term_name(term, false)
    assert.are.same('MyTerm', other_name)
  end)
end)
