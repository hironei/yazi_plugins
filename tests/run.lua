-- Runs every plugin test in-process. Usage: lua tests/run.lua (from any directory).
local script_dir = (arg[0] or ""):gsub("\\", "/"):match("^(.*)/[^/]*$") or "."
local plugins = { "pane-diff", "pane-link", "bcomp-diff" }

local failed = 0
for _, name in ipairs(plugins) do
	-- Each test script resolves its plugin from arg[0] and installs its own
	-- ya/Command/cx mocks, so give it a fresh arg table and clear the globals.
	local saved_arg = arg
	arg = { [0] = script_dir .. "/" .. name .. "/test_main.lua" }
	ya, Command, cx = nil, nil, nil

	local ok, err = pcall(dofile, arg[0])
	arg = saved_arg
	if not ok then
		failed = failed + 1
		print("FAILED: " .. name .. ": " .. tostring(err))
	end
end

if failed > 0 then
	os.exit(1)
end
print("all " .. #plugins .. " plugin test files passed")
