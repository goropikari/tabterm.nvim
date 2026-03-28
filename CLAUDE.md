# CLAUDE.md

This repository is a Neovim plugin written primarily in Lua.

Your goal is to make the smallest correct change that matches the repository’s existing patterns.
Do not rewrite the repository into your preferred architecture.

---

## Primary editing rules

- Prefer existing project patterns over inventing abstractions.
- Prefer minimal diffs.
- Preserve public API compatibility unless explicitly asked to change it.
- Preserve behavior unless the task explicitly changes behavior.
- Do not introduce new helper modules, wrappers, utilities, or architectural layers unless explicitly requested.
- Do not rename symbols unless necessary for the requested change.
- Do not silently modernize unrelated code.
- Do not generate placeholder code, pseudocode, TODOs, or fake implementations.
- If unsure, say what is uncertain instead of inventing behavior or APIs.

---

## Required workflow

Before making any code changes:

1. Inspect existing repository patterns relevant to the task.
2. Identify the closest precedent already in this repo.
3. Explain a short plan.
4. Only then edit the minimum necessary files.

Before editing, always search for similar existing patterns for:

- user commands
- autocmds / augroups
- keymaps
- setup/config
- state management
- async/timers/jobs
- tests
- docs / help text

If a requested implementation conflicts with existing repository conventions, prefer repository conventions unless explicitly told otherwise.

---

## Neovim / Lua specific rules

### Commands

- Reuse the repository’s existing command registration pattern.
- Prefer consistency with existing `nvim_create_user_command` usage.
- Preserve command UX conventions already used in this repo.

### Autocmds / Augroups

- Reuse existing augroup creation and autocmd registration patterns.
- Avoid duplicate registration.
- Avoid creating hidden side effects during module load unless this repo already does that intentionally.

### Keymaps

- Reuse existing keymap style and option conventions.
- Do not introduce keymaps unless the task explicitly requires them.

### setup() / config

- Reuse existing `setup()` and config merge patterns.
- Do not expand the public config surface unless necessary.
- Avoid adding surprising defaults.

### State

- Reuse existing state management.
- Do not introduce new global state unless the repository already uses that pattern.

### Async / jobs / timers

- Avoid speculative async logic.
- Prefer existing repository precedent for scheduling, timers, uv/loop usage, and callbacks.

### API usage

- Prefer Neovim APIs already used in this repository.
- If you are unsure about an API, first infer from repository precedent.
- Do not invent APIs.

---

## File and architecture rules

- Reuse existing file layout and module boundaries.
- Avoid creating new files unless there is a clear precedent or a strong need.
- Avoid splitting code into “helper” files unless explicitly requested.
- Keep module responsibilities aligned with the current repository structure.

When possible, edit existing files rather than creating new abstractions.

---

## Tests

When behavior changes or new behavior is added:

- Look for existing test style first.
- Reuse existing testing tools and conventions.
- Add or update tests when the repository already has tests for similar behavior.
- Do not invent a new test framework or test style.

Before writing tests, inspect existing tests for:

- naming conventions
- helper usage
- assertion style
- setup/teardown style

---

## Documentation

When behavior or public API changes:

- Update README usage if relevant.
- Update help docs in `doc/` if relevant.
- Keep examples aligned with real behavior.
- Do not document features that do not actually exist.

If there is user-visible behavior, check whether docs should also change.

---

## Review checklist before finishing

Before finishing, verify:

- Is this the smallest reasonable diff?
- Did I follow an existing repository precedent?
- Did I avoid introducing unnecessary abstractions?
- Did I preserve public API unless asked not to?
- Did I avoid guessing about Neovim APIs?
- Are tests/docs needed for this change?
- Did I avoid unrelated cleanup?

---

## Preferred response style

When responding:

1. First say which existing repository pattern you are following.
2. Then give a short plan.
3. Then make the edit.
4. Then summarize exactly what changed.

If the task is ambiguous, ask one narrow clarifying question instead of making broad assumptions.
