# File picker design

See [requirements.md](requirements.md) for scope and the standalone [README](../../file-picker.yazi/README.md) for the process contract.

## Shared implementation policy

The configuration validation, main-context `setup` state, `ya.sync` snapshot, protected invocation, child ownership, write/flush/EOF, cancellation, and permit cleanup patterns follow `zoxide-picker.yazi`. Their implementation is copied into this package rather than imported across install units: each package must remain independently installable. Existing zoxide-picker code/tests are unchanged. Future common lifecycle fixes should be assessed for both copies.

File-specific differences are rg enumeration, NUL-to-LF conversion, regular-file metadata validation, captured-directory URL resolution, and tab-targeted `reveal`. Both processes receive the captured directory as working directory through `Command:cwd(...)`. `--no-config` prevents inherited ripgrep configuration from changing enumeration/framing policy; picker configuration/environment remains user controlled.

## Context and process ownership

Setup copies validated argv into main-context state; async entry reads that state through a synchronous snapshot. Modern jobs use `job.tab` with `cx.tab`; legacy 26.9.1 jobs snapshot active cwd and opaque ID atomically. No subsequent context read supplies the destination. Relative selections are joined to this saved cwd, not the subsequently active tab or process-global directory.

Enumeration completes before hiding Yazi. Its NUL framing detects unsupported newline names. A clean rg no-files status is handled before parsing. The membership set retains exact rg records, while the ordered buffer supplies selector stdin. Selector output is validated only after inspecting status and confirming successful input delivery. Metadata follows file symlinks and requires `is_file`.

The outer scope owns the child and UI permit. Thrown errors independently attempt kill/reap, then drop the permit. Ordinary `wait_with_output` consumes the child. Notification or `reveal` occurs after restoration; failed restoration prevents emission. `raw = true` avoids path expansion and the captured opaque `tab` preserves destination identity.

## Impact assessment

| Area | Assessment |
| --- | --- |
| Implementation/callers | New opt-in package and examples; other plugins untouched. |
| Types/validation/serialization | Validated Lua setup and explicit stdin/stdout byte contract; no persisted DTO. |
| API/routing/permissions/errors | Yazi Command, metadata, context, UI permit, and reveal APIs; no network route or authorization changes. |
| Configuration/environment/defaults/migration | Explicit selector setup, rg default ignore rules with config disabled; the primary `on = "z"` example replaces the existing lowercase `z` binding while uppercase `Z` stays unchanged. |
| Files/database/cache/persistence | Read-only enumeration/metadata; no file contents, writes, database, or cache. |
| UI/state/events/accessibility | External TUI and saved-tab reveal; actual keys/IME/focus/accessibility require live checks. No web/responsive UI. |
| Translations/messages/logs/metrics | English notifications/docs; no catalog, telemetry, or monitoring. |
| Tests/mocks/fixtures | New process/path/UI mocks, aggregate registration; no external fixtures or E2E claims. |
| Build/scripts/package/CI | Self-contained layout and Lua runner; no dependencies or workflows. Repository has no configured formatter/linter/type checker; syntax and whitespace checks supplement mocks. |
| Documentation/examples | Package/root READMEs, requirements/design, init/keymap examples. |
| Security/privacy/input/secrets | Direct argv and membership validation; trusted executable configuration; no secrets or personal data. |
| Compatibility/existing data/users | Opt-in setup replaces the existing lowercase `z` binding with file-picker; uppercase `Z`, history, and stored data remain unchanged. |

## Local verification

```sh
lua tests/run.lua
git diff --check
luac -p file-picker.yazi/main.lua
luac -p tests/file-picker/test_main.lua
luac -p tests/run.lua
luac -p examples/file-picker/init.lua
```

Mocks cover separate setup/async module instances, exact argv and pipe modes, relative Unix/Windows/UNC paths, Japanese/spaces, candidate membership, file metadata, legacy opaque tab identities, tab switching, cancellation, rg no-files/failure, malformed framing, process exceptions, and cleanup. These checks do not verify live installation, Yazi/GUI/Windows/WSL, external selector behavior, or terminal restoration in an actual host.
