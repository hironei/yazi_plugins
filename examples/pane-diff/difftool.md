# Git Difftool examples

`pane-diff.yazi` resolves Git's configured tool path and runs it with two separate arguments:

```text
<configured-difftool-path> <active-file-or-folder> <other-file-or-folder>
```

## WinMerge

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.path 'C:/Program Files/WinMerge/WinMergeU.exe'
```

## Beyond Compare

```bash
git config --global diff.tool bcompare
git config --global difftool.bcompare.path 'C:/Program Files/Beyond Compare/BCompare.exe'
```

Use `git difftool --tool-help` to check the tool name, and `git config --get difftool.<tool>.path` to check its configured path. The plugin does not invoke `git difftool`, `cmd.exe /c`, `sh -c`, or a shell-built command line. If no `difftool.<tool>.path` is configured, the `diff.tool` name is used as a command expected to be available in `PATH`.
