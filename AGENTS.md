# Repository Instructions

- Write all deliverables in English, including README files, manuals, examples, and user-visible messages, unless a task explicitly requires another language.
- Preserve existing user changes and keep changes within the requested scope.
- Each `*.yazi` directory must be self-contained for `ya pkg add hironei/yazi_plugins:<package>`: it contains `main.lua`, `README.md`, and `LICENSE`, and does not rely on files outside the directory at runtime.
- Keep tests under `tests/<plugin>/` and examples under `examples/<plugin>/`. Run all tests with `lua tests/run.lua` and run `git diff --check` before reporting completion.
- Update the plugin README and the root `README.md` when behavior, setup, or limitations change.
- Distinguish automated results (Lua mock tests) from live Yazi, GUI, Windows, and external-tool verification, and never report live verification that was not performed.
