.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .

.PHONY: lint
lint:
	typos -w

.PHONY: check
check: lint fmt

.PHONY: test
test:
	nvim --headless -u test/minimal_init.lua -c "PlenaryBustedDirectory test { minimal_init = './test/minimal_init.lua' }"

.PHONY: up
up:
	devcontainer up --workspace-folder=.

.PHONY: up-new
up-new:
	devcontainer up --workspace-folder=. --remove-existing-container

.PHONY: exec
exec:
	devcontainer exec --workspace-folder=. bash
