# File picker requirements

Implementation scope: [Issue #8](https://github.com/hironei/yazi_plugins/issues/8). The standalone [package README](../../file-picker.yazi/README.md) is the authoritative setup, protocol, and limitations reference; [design.md](design.md) records implementation decisions.

- Provide an opt-in, self-contained `file-picker.yazi` containing `main.lua`, `README.md`, and `LICENSE`. The primary keymap example uses `on = "z"` to replace the existing lowercase `z` binding. Keep uppercase `Z`, Zoxide history, and `zoxide-picker.yazi` unchanged.
- Configure exactly one executable and literal argv through `require("file-picker"):setup { command = ..., args = {...} }`, with no implicit selector or shell strings.
- Enumerate files below the captured tab directory through rg's Command API. Preserve candidate bytes/order, reject unsupported names, and send LF-delimited UTF-8 paths through selector stdin with explicit flush/EOF.
- Accept only one exact supplied path from successful stdout and verify it resolves to an existing regular file. Handle cancellation, empty output/list, missing commands, process errors, malformed output, and stale files without revealing anything.
- Restore the TUI on every owned-permit path and reveal only in the captured tab. Follow zoxide-picker's modern and Yazi 26.9.1 legacy context policy, preserving opaque IDs.
- Supply English docs, `examples/file-picker/`, `tests/file-picker/`, root README registration, and `tests/run.lua` registration. Keep runtime code independent of other packages.
- Run `lua tests/run.lua`, `git diff --check`, and Lua syntax checks. Distinguish mocked validation from unperformed live Yazi/GUI/Windows/WSL/external-selector checks.

No dependency changes, remote CI, commits, pushes, PRs, persisted configuration formats, bundled executables, multi-selection, file-content search, alternate delimiters, or path conversion are in scope. Large-tree memory use, arbitrary hung selectors, and filesystem races remain documented limits.
