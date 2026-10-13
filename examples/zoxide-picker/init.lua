-- Add to Yazi's init.lua. Keep this setup independent of picker navigation.
-- If already present, keep the existing line rather than subscribing twice.
require("zoxide"):setup { update_db = true }

-- Choose exactly ONE picker block. Options are illustrative: verify your
-- installed picker's ordering, output, cancellation, and terminal behavior.

-- SagasuFinder (sgs) example:
require("zoxide-picker"):setup {
	command = "sgs",
	args = { "--no-sort", "--exit-0" },
}

-- Yuru alternative: replace the block above with this block; do not enable both.
-- require("zoxide-picker"):setup {
-- 	command = "yuru",
-- 	args = { "--no-sort", "--exit-0", "--lang", "ja" },
-- }

-- command is one executable name or path, never a shell command string.
-- For an executable path containing spaces on Windows, use a Lua long string:
-- command = [[C:\Program Files\Picker\selector.exe]]
-- Arguments remain separate literal strings in args (use {} for no arguments).
