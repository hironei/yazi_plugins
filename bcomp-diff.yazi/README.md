# bcomp-diff.yazi

`bcomp-diff.yazi` opens exactly two selected files in [Beyond Compare](https://www.scootersoftware.com/) (`BComp.exe`) from Yazi.

## Requirements

| Dependency | Requirement |
| --- | --- |
| Yazi | 26.8.15 tested baseline; 26.5.6 selected-URL compatibility is retained |
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

Beyond Compare is started with the two selected paths, in selection order, as separate arguments.

| Selected files | Behavior |
| --- | --- |
| 0 | Nothing is launched; a warning notification explains that two files are required. |
| 1 | Nothing is launched; a warning notification explains that two files are required. |
| 2 | `BComp.exe <first> <second>` is launched. |
| 3 or more | Nothing is launched; a warning notification reports the number selected. |

If `BComp.exe` cannot be started (for example it is not in `PATH`), an error notification is shown.

## Notes

- Paths are passed through `Command:arg`, never concatenated into a shell string, so paths containing spaces, parentheses, or non-ASCII characters (for example `C:\Program Files\My Docs\a b.txt`) need no quoting.
- The plugin does not wait for Beyond Compare to exit, and does not inspect whether a selected entry is a file or a folder.
- The hovered item is not used; only explicitly selected entries are compared. Selection state and cursor position are not changed.

## Testing

```bash
lua tests/bcomp-diff/test_main.lua
```

The mock tests cover 0, 1, 2, 3, and 4 selected files, paths with spaces, direct-URL selected values from older Yazi versions, and spawn failures. They do not replace live verification in Yazi on Windows with Beyond Compare installed.

## License

MIT License. See [`LICENSE`](LICENSE) for the full text.
