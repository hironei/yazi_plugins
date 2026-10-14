# File picker

Reveal a file below the invoking tab's directory using ripgrep and a configurable external selector. Requires Yazi 26.9.1 or later, matching `ya`, `rg` (ripgrep), and a separately installed selector implementing the contract below.

## Install and configure

```sh
ya pkg add hironei/yazi_plugins:file-picker
```

Add to Yazi's `init.lua`:

```lua
require("file-picker"):setup {
    command = "sgs",
    args = { "--no-sort", "--exit-0" },
}
```

Alternatively, replace that block with:

```lua
require("file-picker"):setup {
    command = "yuru",
    args = { "--no-sort", "--exit-0", "--lang", "ja" },
}
```

These options are illustrative, not verified binary compatibility guarantees. Check your installed selector's options, including its output, ordering, and cancellation behavior. Any compatible executable can be configured; the plugin adds no selector-specific flags or fallback.

`command` is one executable name resolved through `PATH` or an executable path, without flags or shell quotes. For Windows paths with spaces, use `command = [[C:\Program Files\Picker\selector.exe]]`. `args` is a required consecutive array of literal strings; use `{}` for no arguments. Invalid setup clears previous configuration and returns `(false, error_message)`; invocation reports the error without starting a process. Restart Yazi after changing setup.

Add to `keymap.toml` to replace the existing lowercase `z` binding:

```toml
[[mgr.prepend_keymap]]
on = "z"
run = "plugin file-picker"
desc = "Reveal a file using configured picker"
```

The lowercase `z` binding now invokes file-picker. Keep your existing uppercase `Z` binding and Zoxide configuration unchanged.

## Enumeration and stdin/stdout contract

1. Capture the invoking directory and tab identity before asynchronous work. Run `rg --files --null --color never --no-config` directly through Yazi's `Command` API with that directory as the process working directory. No shell or shell pipeline is used. Ripgrep recursively lists files with its default ignore/hidden-file rules; hidden and ignored files are excluded, and directory symlinks are not followed. Ripgrep configuration files are disabled. No file contents are searched and no sorting is added; enumeration order is not guaranteed.
2. Parse NUL-delimited rg paths and reject invalid UTF-8, blank paths, and embedded CR/LF names. Convert records to UTF-8 LF-delimited selector stdin, preserving spaces, Japanese names, separators, and order. Paths are normally relative to the captured directory. Empty successful enumeration, or rg status `1` with no stdout/stderr, leaves Yazi visible and starts no selector. Other enumeration failures report stderr and do not launch a selector.
3. Hide Yazi and run the configured executable with literal argv and the same captured working directory. Stdin and stdout are piped; stderr is inherited. The selector must read candidates through EOF, using stderr or its controlling terminal for UI and interactive input. Input is flushed before `wait_with_output()` closes stdin and drains stdout.
4. Selector stdout must contain exactly one supplied raw path, optionally followed by one LF or CRLF. It must preserve the supplied path exactly: no scores, decorations, query echoes, absolute-path conversion, multiple selections, or diagnostics on stdout. Configure ordering/filtering behavior yourself. A different protocol needs a user-supplied adapter executable.
5. Status `0` with valid output triggers exact candidate-membership validation. Resolve the path using Yazi's `Url(captured_directory):join(path)` and require an existing regular file with `fs.cha(..., true)` (file symlinks resolve to their target). Directories, missing files, foreign paths, and malformed output are errors. Restore Yazi, then emit `reveal` with `raw = true` and the saved tab identity; selection reveals the file rather than opening it.
6. Status `1`/`130`, or empty successful stdout, cancels quietly. Cancellation ignores stdout and tolerates an early broken pipe. Other statuses, missing tools, incomplete input, and launch/read/write/metadata failures produce an error after UI restoration. Exceptions trigger best-effort child kill/reap before releasing the UI permit.

For Yazi 26.9.1 jobs without `job.tab`, the first synchronous snapshot captures `cx.active.current.cwd` and the exact opaque `cx.active.id` together. This is the then-active tab because that version supplies no invoking identity. Later tab switches cannot redirect the result. Modern jobs use `job.tab` and `cx.tab.current.cwd`; missing modern context does not fall back to the active tab. Missing context or identity fails before enumeration. Yazi handles a tab removed before the final event.

## Limitations and troubleshooting

Use executables and paths from the same environment as Yazi: native Windows tools for Windows Yazi, Linux tools for WSL Yazi. There is no Windows/WSL path conversion or shell quoting. Names containing CR/LF and non-UTF-8 paths are unsupported; rg's NUL framing lets the plugin detect newline names rather than silently split them.

Candidate lists are buffered in memory, without a count cap or interaction timeout. Very large trees, hung selectors, or selectors writing unbounded stdout before consuming stdin can exhaust memory or block. A file can disappear after validation; Yazi handles that final filesystem race. Executable configuration is trusted local configuration, not a sandbox. If Yazi's UI permit-drop primitive itself fails, the plugin reports that error and does not reveal a file.

- Missing `rg` or selector: check installation, executable permissions, and Yazi's inherited `PATH`.
- Empty list: check rg's ignore/hidden rules and the invoking directory; no selector is launched.
- Invalid selection: disable stdout decorations and path conversion; send diagnostics/UI to stderr or the terminal.
- Stale selection: choose an existing regular file; the file may have been removed while selecting.
- Missing tab context: check Yazi and matching `ya` versions (minimum 26.9.1).
- Display, keys, IME, or focus issues: verify the selector in your actual terminal host.

## Verification boundary

Automated verification uses Lua mocks for configuration, process argv/working directories, bytes, EOF, cancellation, errors, metadata, saved tab targeting, and permit cleanup. **Live Yazi, GUI, Windows, WSL, sgs/Yuru, package installation, and Yazi Terminal verification is NOT performed.** Mock success does not establish executable or terminal compatibility.

Users should install/configure the package and test nested files with spaces and Japanese names, selection after a tab switch, Escape/Ctrl-C, no matches, empty trees, missing tools, stale files, and malformed selector output. Confirm Yazi restores its TUI and reveals in the captured tab. Check filtering, Japanese/romaji matching if supported, keys, IME, display, focus, and restoration separately in every intended host/environment. Yazi Terminal compatibility is not guaranteed.

## License

MIT. See [LICENSE](LICENSE). External tools have their own licenses.
