# yazi_plugins

A collection of small [Yazi](https://yazi-rs.github.io/) plugins, published from one repository. Each plugin lives in its own `*.yazi` directory and can be installed individually with `ya pkg add hironei/yazi_plugins:<package>`.

## Plugins

| Plugin | Summary | Install | Documentation |
| --- | --- | --- | --- |
| `pane-diff` | Sends one selected or hovered target from each of two `split-tabs.yazi` panes to the external Diff tool configured through Git. | `ya pkg add hironei/yazi_plugins:pane-diff` | [pane-diff.yazi/README.md](pane-diff.yazi/README.md) |
| `pane-link` | Creates a link to the active pane's file or folder in the other pane's current directory. | `ya pkg add hironei/yazi_plugins:pane-link` | [pane-link.yazi/README.md](pane-link.yazi/README.md) |
| `bcomp-diff` | Opens exactly two selected files in Beyond Compare (`BComp.exe`). | `ya pkg add hironei/yazi_plugins:bcomp-diff` | [bcomp-diff.yazi/README.md](bcomp-diff.yazi/README.md) |
| `zoxide-picker` | Jumps through Zoxide history using an executable and argv configured in Yazi's `init.lua`. | `ya pkg add hironei/yazi_plugins:zoxide-picker` | [zoxide-picker.yazi/README.md](zoxide-picker.yazi/README.md) |

`pane-diff` and `pane-link` also require `terrakok/split-tabs.yazi`:

```bash
ya pkg add terrakok/split-tabs
```

## Installation example

```bash
ya pkg add hironei/yazi_plugins:pane-diff
ya pkg add hironei/yazi_plugins:pane-link
ya pkg add hironei/yazi_plugins:bcomp-diff
ya pkg add hironei/yazi_plugins:zoxide-picker
```

Then add the keymap shown in each plugin's README (ready-to-copy files are in [`examples/`](examples/)). Update with `ya pkg upgrade`; remove a plugin with `ya pkg delete hironei/yazi_plugins:<package>`.

## Environment notes

- Tested baseline: Yazi 26.8.15 with the matching `ya` version (Lua mock tests). `pane-diff` also keeps compatibility with the older direct selected-URL shape (Yazi 26.5.6); `pane-link` requires 26.5.6 or later.
- `zoxide-picker` requires the current tab-scoped Yazi APIs (`cx.tab`, `job.tab`, and tab-targeted `ya.emit`) and a configured picker that accepts ordered UTF-8 paths on stdin and returns one raw path on stdout. Older baseline claims above apply to the existing plugins. See its [README](zoxide-picker.yazi/README.md) for mutually exclusive sgs/Yuru configuration examples and protocol details.
- `pane-diff` and `pane-link` target Git Bash on Windows, WSL, Linux, or macOS (see each README for details); `bcomp-diff` targets Windows with Beyond Compare in `PATH`.
- Live verification (Yazi 26.9.1 on Windows 11 with Git Bash; see the table below).
- Yazi and the tools a plugin launches must run in the same environment.
- Lua is only needed to run the repository's mock tests, not at runtime.
- Yazi APIs may change; retest after upgrading.

## Live verification status

Performed manually after PR #2 was merged ([Issue #3](https://github.com/hironei/yazi_plugins/issues/3)), using Yazi 26.9.1 with the matching `ya` on Windows 11 with Git Bash.

| Plugin | `ya pkg add` | Live execution | Notes |
| --- | --- | --- | --- |
| `pane-diff` | Verified | Verified | Beyond Compare was launched through Git's difftool. Yazi may report an error with a negative exit code (for example `-13`) when the tool exits; it has no practical effect. |
| `pane-link` | Verified | Verified | |
| `bcomp-diff` | Verified | Verified | Earlier versions failed to start Beyond Compare or left a background task; fixed by running Yazi's `shell` command with `orphan = true` ([Issue #4](https://github.com/hironei/yazi_plugins/issues/4)). |

Not covered: other Yazi versions, WSL, Linux, macOS, and other Diff tools.

`zoxide-picker` has Lua mock verification only; no live installation, sgs/Yuru execution, regular Yazi, WSL, or Yazi Terminal verification is claimed. Users verify their chosen picker's options, ordering, matching, TUI/IME/focus, terminal restoration, and platform paths. Yazi Terminal may be usable with matching native Windows tools, but compatibility is not guaranteed and live verification is not a maintainer implementation gate. Keep the independent `require("zoxide"):setup { update_db = true }` history setup when replacing the `Z` picker.

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

For `zoxide-picker`, see the [requirements](docs/zoxide-picker/requirements.md), [design](docs/zoxide-picker/design.md), and [configuration examples](examples/zoxide-picker/). Only the example uppercase `Z` binding is replaced; unrelated keymaps and Zoxide history collection remain independently configured.

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
