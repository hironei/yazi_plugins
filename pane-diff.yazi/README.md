# pane-diff.yazi

`pane-diff.yazi` compares the target under the cursor, or one explicitly selected target, from each of two panes shown by `terrakok/split-tabs.yazi`. Targets may be files or folders. It passes both paths directly to the external Diff tool whose path is configured through Git.

## Requirements

| Dependency | Requirement |
| --- | --- |
| Environment | Git Bash or WSL, with Yazi and Git running in the same environment |
| Yazi | 26.8.15 tested baseline; 26.5.6 selected-URL compatibility is retained |
| `ya` | The same version as Yazi, for installing `split-tabs.yazi` |
| `terrakok/split-tabs.yazi` | Required for the two-pane view |
| Git | The same environment's `PATH` contains `git`, with `diff.tool` configured and its `difftool.<tool>.path` set or the tool name available in `PATH` |
| Lua | Not required at runtime; only needed for the repository's mock tests |

At minimum, verify that these commands succeed:

```bash
yazi --version
ya --version
git --version
git difftool --tool-help
```

The plugin is tested against the public APIs available in Yazi 26.8.15 and the current `split-tabs.yazi` implementation. The small selected-entry adapter also accepts the direct URL shape used by older Yazi versions. Yazi APIs may change; retest the plugin after upgrading.

## Installation

### 1. Install split-tabs.yazi

Install the pane provider with Yazi's package manager:

```bash
ya pkg add terrakok/split-tabs
```

### 2. Install pane-diff.yazi

Install the plugin from its repository subdirectory:

```bash
ya pkg add hironei/yazi_plugins:pane-diff
```

`ya pkg` downloads the repository and places the plugin in Yazi's plugin directory. It records the installation in `package.toml`. Update it with `ya pkg upgrade`, or remove it with:

```bash
ya pkg delete hironei/yazi_plugins:pane-diff
```

### 3. Verify the installation

For Windows Yazi used from Git Bash, verify `%AppData%/yazi/config/plugins/pane-diff.yazi/main.lua`. For Linux Yazi used from WSL, verify `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/plugins/pane-diff.yazi/main.lua`.

The same configuration directory's `package.toml` should contain `hironei/yazi_plugins:pane-diff`.

Restart Yazi after changing its configuration.

## Keymap

Add this to the `keymap.toml` used by your Yazi environment. For Git Bash, this is `%AppData%/yazi/config/keymap.toml` for Windows Yazi. For WSL, it is `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/keymap.toml`.

```toml
[[mgr.prepend_keymap]]
on = [ "g", "d" ]
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

If the `g` prefix conflicts with an existing mapping, choose another key, for example:

```toml
[[mgr.prepend_keymap]]
on = "D"
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

The same example is available in [`examples/pane-diff/keymap.toml`](../examples/pane-diff/keymap.toml).

## Basic operation

1. Enable `split-tabs.yazi` and show two panes.
2. Select one file or folder, or place the cursor on one target, in each pane.
3. Press `g`, then `d`.

The active pane's target is passed as the first argument to the Diff tool, and the other pane's target is passed as the second argument. Switching the active pane therefore reverses the argument order. Physical screen-left and screen-right ordering is not guaranteed.

## Target selection

Each pane uses this priority order:

1. If exactly one target is explicitly selected, use it.
2. If there is no explicit selection, use the target under the cursor.
3. Do not launch when two or more targets are selected.
4. Do not launch when there is no item under the cursor.
5. Do not classify the target as a file, folder, link, or special file; pass its URL to the Diff tool unchanged.

The plugin does not change the selection state, cursor position, or Yazi's current directory.

On Yazi 26.8.15, selected values are `File` entries and the plugin resolves each entry through its `.url`. Direct URL-shaped selected values from older versions remain supported. The target's type is intentionally not inspected.

## Git Difftool configuration

The plugin reads `diff.tool` and `difftool.<tool>.path` from Git, then starts the configured executable directly:

```text
<configured-difftool-path> <active-file-or-folder> <other-file-or-folder>
```

The plugin does not invoke `git difftool`, because Git may expand directory comparisons into individual file invocations. Paths are passed as separate `Command:arg` arguments, so files and folders with spaces, Japanese characters, and parentheses do not depend on shell quoting. Launch, wait, and non-zero process statuses are reported as Yazi notifications.

For example, configure WinMerge as Git's difftool:

- Git Bash: configure a Windows WinMerge executable that Git Bash can start.
- WSL: configure a Linux Diff tool available inside WSL. To use a Windows executable, provide a command that WSL can invoke.

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.path 'C:/Program Files/WinMerge/WinMergeU.exe'
```

See [`examples/pane-diff/difftool.md`](../examples/pane-diff/difftool.md) for more examples. Paths are passed as separate `Command:arg` arguments, so spaces, Japanese characters, and parentheses do not depend on shell quoting.

## Notifications and troubleshooting

- Fewer or more than two tabs: enable `split-tabs.yazi` and show exactly two tabs.
- No target or multiple selection: select or place the cursor on exactly one target in each pane.
- `git` is missing or no difftool path is configured: check `git --version`, `git difftool --tool-help`, and `git config --get difftool.<tool>.path`.
- Process launch failure: check the Diff tool executable's `PATH` and Git's difftool configuration.

The external process is started asynchronously and its exit state is monitored through Yazi's asynchronous API. Launch failures, wait failures, and non-zero exit statuses are reported as Yazi notifications. Waiting for the Diff tool does not block Yazi's main operation.

## Direct-launch extension

The plugin uses the path configured by Git for the selected `diff.tool`. To use WinMerge, Beyond Compare, or another tool that accepts two path arguments, configure its executable path with `difftool.<tool>.path`. Do not turn paths into a shell-built command string.

```lua
Command("configured-difftool-path")
	:arg { path1, path2 }
	:spawn()
```

## Known limitations and unsupported scope

- Three or more panes, three or more targets, and an in-Yazi Diff viewer are not supported.
- Operating on an inactive pane or comparing multiple selected targets as a batch is not supported.
- The plugin reads the two tabs from Yazi's public `cx.tabs` API and does not modify `split-tabs.yazi` internals. A stable public mapping from `split-tabs.yazi` to physical screen-left/screen-right order is not available, so physical left/right ordering is not guaranteed.
- Yazi state alone cannot detect a target deleted immediately before comparison. In that case, the Diff tool's launch or exit status is reported as a Yazi notification.

The remaining unsupported capabilities and live acceptance work are tracked in [Issue #2 in the original repository](https://github.com/hironei/yazi_split_pane_diff/issues/2). Compatibility and live acceptance for the Yazi 26.8.15 selected-entry contract are tracked in [Issue #4 in the original repository](https://github.com/hironei/yazi_split_pane_diff/issues/4). The Lua mock tests do not cover the real Yazi screen, `split-tabs.yazi`, a configured external Diff GUI, Windows IME, or Windows focus behavior.

## Testing

Run the Lua mock tests with:

```bash
lua tests/pane-diff/test_main.lua
```

These tests do not replace live acceptance in Yazi, `split-tabs.yazi`, Git's external Difftool GUI, or Windows input and focus behavior.

## License

MIT License. See [`LICENSE`](LICENSE) for the full text.
