# Design: English Documentation and Unsupported Scope Tracking

## Scope

This is a documentation-only change. The plugin implementation and test harness remain unchanged.

## Documentation structure

- `AGENTS.md` holds repository-wide authoring rules.
- `README.md` provides the repository-level overview, prerequisites, installation, configuration, and test entry point.
- `pane-diff.yazi/README.md` provides the plugin manual, behavior rules, troubleshooting, and limitations.
- [Issue #2 in the original repository](https://github.com/hironei/yazi_split_pane_diff/issues/2) records unsupported capabilities and live acceptance work that must not be mistaken for automated coverage.

## Unsupported-scope boundary

- Physical screen-left/screen-right ordering remains unsupported because the plugin uses Yazi's public `cx.tabs` API and no stable public mapping from `split-tabs.yazi` to physical sides is available.
- Three or more panes, bulk comparison of multiple selected targets, and an in-Yazi diff viewer remain separate feature work.
- Live validation of Yazi, `split-tabs.yazi`, Git's configured external Diff GUI, Windows focus, and IME behavior requires an environment that is not represented by the Lua mocks.

## Safety and compatibility

The change preserves separate path arguments, Git Bash/WSL setup, and the current Yazi version baseline. The direct tool path is resolved from Git's `diff.tool` and `difftool.<tool>.path` settings.
