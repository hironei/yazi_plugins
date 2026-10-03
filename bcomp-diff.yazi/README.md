# bcomp-diff.yazi

`bcomp-diff.yazi` opens exactly two selected files in [Beyond Compare](https://www.scootersoftware.com/) (`BComp.exe`) from Yazi.

## Requirements

| Dependency | Requirement |
| --- | --- |
| Yazi | 26.5.6 or later (uses `ya.emit("shell", ...)`); see [Live verification history](#live-verification-history) |
| `ya` | The same version as Yazi, for installing the plugin |
| Beyond Compare | `BComp.exe` must be resolvable through the `PATH` of the environment that runs Yazi |
| Lua | Not required at runtime; only needed for the repository's mock tests |

## Installation

```bash
ya pkg add hironei/yazi_plugins:bcomp-diff
```

Update it with `ya pkg upgrade`, or remove it with:

```bash
ya pkg delete hironei/yazi_plugins:bcomp-diff
```

Restart Yazi after changing its configuration.

## Keymap

Add this to the `keymap.toml` used by your Yazi environment (on Windows, `%AppData%/yazi/config/keymap.toml`):

```toml
[[mgr.prepend_keymap]]
on = [ "g", "D" ]
run = "plugin bcomp-diff"
desc = "Diff two selected files"
```

The same example is available in [`examples/bcomp-diff/keymap.toml`](../examples/bcomp-diff/keymap.toml).

## Usage

1. Select exactly two files in the active tab (for example with `Space`).
2. Press `g`, then `D`.

After checking the selection count, the plugin runs Yazi's own `shell` command with `BComp.exe %s1 %s2` as an orphan (detached) process, so Yazi does not keep it as a background task. Yazi expands and quotes the two selected paths, exactly as the keymap entry `run = 'shell -- BComp.exe %s1 %s2'` would.

| Selected files | Behavior |
| --- | --- |
| 0 | Nothing is launched; a warning notification explains that two files are required. |
| 1 | Nothing is launched; a warning notification explains that two files are required. |
| 2 | `shell` runs `BComp.exe %s1 %s2`. |
| 3 or more | Nothing is launched; a warning notification reports the number selected. |

If `BComp.exe` cannot be started (for example it is not in `PATH`), Yazi's own shell error handling applies; the plugin does not report launch errors itself.

## Notes

- The plugin does not build the command line itself, so path quoting is Yazi's `%s1` / `%s2` expansion. Paths with spaces or non-ASCII characters must be verified live.
- The plugin does not inspect whether a selected entry is a file or a folder.
- The hovered item is not used; only explicitly selected entries are compared. Selection state and cursor position are not changed.

## Live verification history

On Yazi 26.9.1 (Windows 11, Git Bash), [Issue #4](https://github.com/hironei/yazi_plugins/issues/4) found two problems in earlier versions:

1. Starting `BComp.exe` with `Command(...):spawn()` did not launch Beyond Compare.
2. Running it through Yazi's `shell` command launched Beyond Compare, but left a "Background command: BComp.exe" task in Yazi after Beyond Compare exited.

The current version passes `orphan = true` to `shell`. It was verified manually on the same environment: Beyond Compare starts with `g`, `D` on two selected files, and no task remains after Beyond Compare is closed. Other environments were not live-verified.

## Testing

```bash
lua tests/bcomp-diff/test_main.lua
```

The mock tests cover 0, 1, 2, 3, and 4 selected files, a missing tab, and the emitted `shell` command line. They do not replace live verification in Yazi on Windows with Beyond Compare installed.

## License

MIT License. See [`LICENSE`](LICENSE) for the full text.
