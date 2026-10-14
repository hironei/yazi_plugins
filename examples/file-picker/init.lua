-- Add to Yazi's init.lua. Choose exactly one selector configuration.
-- These flags are illustrative; verify your installed selector's contract.
require("file-picker"):setup {
	command = "sgs",
	args = { "--no-sort", "--exit-0" },
}

-- Yuru alternative: replace the block above; do not enable both.
-- require("file-picker"):setup {
-- 	command = "yuru",
-- 	args = { "--no-sort", "--exit-0", "--lang", "ja" },
-- }

-- command is a single executable name/path, never a shell command string.
-- Windows example: command = [[C:\Program Files\Picker\selector.exe]]
-- args contains literal argv strings; use {} for no arguments.
