# yazi_plugins

A collection of small [Yazi](https://yazi-rs.github.io/) plugins, published from one repository. Each plugin lives in its own `*.yazi` directory and can be installed individually with `ya pkg add hironei/yazi_plugins:<package>`.

## Plugins

| Plugin | Summary | Install | Documentation |
| --- | --- | --- | --- |
| `pane-diff` | Sends one selected or hovered target from each of two `split-tabs.yazi` panes to the external Diff tool configured through Git. | `ya pkg add hironei/yazi_plugins:pane-diff` | [pane-diff.yazi/README.md](pane-diff.yazi/README.md) |
| `pane-link` | Creates a link to the active pane's file or folder in the other pane's current directory. | `ya pkg add hironei/yazi_plugins:pane-link` | [pane-link.yazi/README.md](pane-link.yazi/README.md) |
| `bcomp-diff` | Opens exactly two selected files in Beyond Compare (`BComp.exe`). | `ya pkg add hironei/yazi_plugins:bcomp-diff` | [bcomp-diff.yazi/README.md](bcomp-diff.yazi/README.md) |

`pane-diff` and `pane-link` also require `terrakok/split-tabs.yazi`:

```bash
ya pkg add terrakok/split-tabs
```

## Installation example

```bash
ya pkg add hironei/yazi_plugins:pane-diff
ya pkg add hironei/yazi_plugins:pane-link
ya pkg add hironei/yazi_plugins:bcomp-diff
```

Then add the keymap shown in each plugin's README (ready-to-copy files are in [`examples/`](examples/)). Update with `ya pkg upgrade`; remove a plugin with `ya pkg delete hironei/yazi_plugins:<package>`.

## Environment notes

- Tested baseline: Yazi 26.8.15 with the matching `ya` version. `pane-diff` and `bcomp-diff` also keep compatibility with the older direct selected-URL shape (Yazi 26.5.6); `pane-link` requires 26.5.6 or later.
- `pane-diff` and `pane-link` target Git Bash on Windows, WSL, Linux, or macOS (see each README for details); `bcomp-diff` targets Windows with Beyond Compare in `PATH`.
- Yazi and the tools a plugin launches must run in the same environment.
- Lua is only needed to run the repository's mock tests, not at runtime.
- Yazi APIs may change; retest after upgrading.

## Repository layout

```text
<plugin>.yazi/        install unit: main.lua, README.md, LICENSE
tests/<plugin>/       Lua mock tests
tests/run.lua         runs every test file
examples/<plugin>/    keymap and configuration examples
docs/<plugin>/        requirements and design notes
docs/migration-notices/  drafts of notices for the original repositories
```

## Testing

```bash
lua tests/run.lua
```

The mock tests do not replace live verification in Yazi, `split-tabs.yazi`, external Diff GUIs, or Windows input and focus behavior.

## Migration from the original repositories

This repository consolidates two earlier single-plugin repositories:

- `hironei/yazi_split_pane_diff` -> `pane-diff`
- `hironei/yazi_split_pane_link` -> `pane-link`

The plugin code is unchanged. Only the install command differs; the old commands point at the old repositories and should be replaced:

| Plugin | Old install command | New install command |
| --- | --- | --- |
| `pane-diff` | `ya pkg add hironei/yazi_split_pane_diff:pane-diff` | `ya pkg add hironei/yazi_plugins:pane-diff` |
| `pane-link` | `ya pkg add hironei/yazi_split_pane_link:pane-link` | `ya pkg add hironei/yazi_plugins:pane-link` |

To migrate, delete the old package (`ya pkg delete hironei/yazi_split_pane_diff:pane-diff`), install the new one, and keep your keymap unchanged. Drafts of the notices for the old repositories are in [`docs/migration-notices/`](docs/migration-notices/).

## License

MIT License. See [LICENSE](LICENSE).
