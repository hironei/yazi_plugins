local script_dir = (arg[0] or ""):gsub("\\", "/"):match("^(.*)/[^/]*$") or "."
local source = arg[1] or (script_dir .. "/../../zoxide-picker.yazi/main.lua")

local owner, plugin, state
local invoking_tab = "tab-invoking"
local cwd = "C:\\current folder\\日本語"
local first = "C:\\visited folder\\日本語 (one)"
local second = "/home/user/other path"
local function result(code, stdout)
	return { status = { code = code, success = code == 0 }, stdout = stdout or "", stderr = "" }
end
local function equal(actual, expected, message)
	assert(actual == expected, (message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function event(value)
	state.events[#state.events + 1] = value
end

ya = {
	sync = function(fn)
		return function(...) return fn(owner, ...) end
	end,
	notify = function(value)
		equal(state.hidden, false, "notification after restoration")
		state.notifications[#state.notifications + 1] = value
	end,
	emit = function(name, args)
		equal(state.hidden, false, "navigation after restoration")
		if state.emit_exception then error("emit exception") end
		state.emitted[#state.emitted + 1] = { name = name, args = args }
		event("cd")
	end,
}
ui = {
	hide = function()
		if state.hide_exception then error("hide exception") end
		equal(state.hidden, false, "UI hidden once")
		state.hidden = true
		state.hides = state.hides + 1
		event("hide")
		return { drop = function()
			equal(state.hidden, true, "permit held until drop")
			state.hidden = false
			state.drops = state.drops + 1
			event("drop")
		end }
	end,
}
Url = function(path)
	return setmetatable({ path = path }, { __tostring = function(value) return value.path end })
end
fs = {
	cha = function(url, follow)
		equal(follow, true, "follow directory symlinks")
		state.inspected = tostring(url)
		if state.cha_exception then error("metadata exception") end
		if state.missing_directory then return nil, "not found" end
		return { is_dir = not state.regular_file }
	end,
}

Command = setmetatable({ NULL = "null", PIPED = "piped", INHERIT = "inherit" }, {
	__call = function(_, executable)
		if state.constructor_exception == executable then error("constructor exception") end
		local command = { executable = executable }
		state.commands[#state.commands + 1] = command
		function command:arg(args)
			equal(type(args), "table", "argv vector")
			self.args = args
			return self
		end
		for _, stream in ipairs { "stdin", "stdout", "stderr" } do
			command[stream] = function(self, value)
				self[stream .. "_mode"] = value
				return self
			end
		end
		function command:output()
			equal(state.hidden, false, "query before hide")
			if state.query_exception then error("query exception") end
			if state.query_error then return nil, "query launch/read failure" end
			return state.query
		end
		function command:spawn()
			equal(state.hidden, true, "picker launch while hidden")
			if state.spawn_exception then error("spawn exception") end
			if state.spawn_error then return nil, "executable not found" end
			-- Simulate another tab becoming active while the async picker runs.
			cx.tab = { current = { cwd = Url("/another/tab") } }
			event("spawn")
			local child = {}
			function child:write_all(input)
				equal(state.hidden, true, "write while hidden")
				state.input = input
				event("write")
				if state.write_exception then error("write exception") end
				if state.write_error then return false, "broken pipe" end
				return true
			end
			function child:flush()
				event("flush")
				if state.flush_exception then error("flush exception") end
				if state.flush_error then return false, "flush failure" end
				state.flushed = state.input
				return true
			end
			function child:wait_with_output()
				equal(state.hidden, true, "wait while hidden")
				state.stdin_closed = true -- Yazi closes stdin before draining stdout.
				event("eof/wait")
				if state.wait_exception then error("wait exception") end
				if state.wait_error then return nil, "output read failure" end
				return state.picker
			end
			function child:start_kill()
				state.killed = true
				event("kill")
				if state.cleanup_exception then error("kill exception") end
				return true
			end
			function child:wait()
				state.reaped = true
				event("reap")
				if state.cleanup_exception then error("reap exception") end
				return { code = 130, success = false }
			end
			return child
		end
		return command
	end,
})

local function reset()
	state = {
		notifications = {}, emitted = {}, commands = {}, events = {},
		hidden = false, hides = 0, drops = 0,
		query = result(0, first .. "\n" .. second .. "\n"),
		picker = result(0, first .. "\n"),
	}
	owner = assert(loadfile(source))()
	-- Entry gets a separately loaded module, as in Yazi's async runtime.
	plugin = assert(loadfile(source))()
	cx = { tab = { current = { cwd = Url(cwd) } } }
	assert(owner:setup { command = "custom-picker", args = { "--preserve-order", "literal value" } })
end
local function run(job)
	plugin:entry(job or { tab = invoking_tab })
end
local function no_navigation()
	equal(#state.emitted, 0, "no navigation")
end
local function error_contains(fragment)
	no_navigation()
	equal(#state.notifications, 1, "error notification count")
	equal(state.notifications[1].level, "error", "error notification level")
	assert(state.notifications[1].content:find(fragment, 1, true), state.notifications[1].content)
end
local tests = 0
local function test(name, fn)
	reset()
	local ok, err = pcall(fn)
	assert(ok, name .. ": " .. tostring(err))
	equal(state.hidden, false, name .. " UI restored")
	equal(state.drops, state.hides, name .. " permit release count")
	tests = tests + 1
end

test("missing setup", function()
	owner.config = nil
	run()
	error_contains("init.lua")
	equal(#state.commands, 0)
end)

local invalid_configs = {
	false, "picker --flags", {}, { command = "", args = {} },
	{ command = " \t", args = {} }, { command = "bad\0name", args = {} },
	{ command = "bad\nname", args = {} }, { command = 5, args = {} },
	{ command = "picker" }, { command = "picker", args = "--flags" },
	{ command = "picker", args = { [2] = "gap" } },
	{ command = "picker", args = { flag = "named" } },
	{ command = "picker", args = { [0] = "zero" } },
	{ command = "picker", args = { [1.5] = "fraction" } },
	{ command = "picker", args = { false } },
	{ command = "picker", args = { "bad\0arg" } },
}
for index, config in ipairs(invalid_configs) do
	test("invalid config " .. index, function()
		local accepted, message = owner:setup(config)
		equal(accepted, false)
		assert(type(message) == "string" and message ~= "")
		run()
		error_contains(message)
		equal(#state.commands, 0)
	end)
end

test("exact pipeline and invoking tab", function()
	run()
	equal(#state.commands, 2)
	local query, picker = state.commands[1], state.commands[2]
	equal(query.executable, "zoxide")
	equal(table.concat(query.args, "|"), "query|--list|--exclude|" .. cwd)
	equal(query.stdin_mode, Command.NULL)
	equal(query.stdout_mode, Command.PIPED)
	equal(query.stderr_mode, Command.PIPED)
	equal(picker.executable, "custom-picker")
	equal(#picker.args, 2)
	equal(picker.args[1], "--preserve-order")
	equal(picker.args[2], "literal value")
	equal(picker.stdin_mode, Command.PIPED)
	equal(picker.stdout_mode, Command.PIPED)
	equal(picker.stderr_mode, Command.INHERIT)
	equal(state.input, first .. "\n" .. second .. "\n", "frecency order and UTF-8 bytes")
	equal(state.flushed, state.input, "buffer flushed before EOF")
	equal(state.stdin_closed, true)
	equal(table.concat(state.events, ","), "hide,spawn,write,flush,eof/wait,drop,cd")
	equal(#state.emitted, 1)
	equal(state.emitted[1].name, "cd")
	equal(state.emitted[1].args[1], first)
	equal(state.emitted[1].args.raw, true)
	equal(state.emitted[1].args.tab, invoking_tab)
	equal(#state.notifications, 0)
end)

test("config-only switch and owned literal argv", function()
	local args = { "", "a;$(echo injected)", [[C:\path with spaces\日本語]], "--different" }
	assert(owner:setup { command = [[C:\Program Files\Picker\selector.exe]], args = args })
	args[2] = "mutated"
	state.picker.stdout = second -- A final record terminator is optional.
	run()
	equal(state.commands[2].executable, [[C:\Program Files\Picker\selector.exe]])
	equal(state.commands[2].args[1], "")
	equal(state.commands[2].args[2], "a;$(echo injected)")
	equal(state.commands[2].args[3], [[C:\path with spaces\日本語]])
	equal(#state.commands[2].args, 4)
	equal(state.emitted[1].args[1], second)
end)

test("empty argv is explicit and accepted", function()
	assert(owner:setup { command = "another-picker", args = {} })
	run()
	equal(#state.commands[2].args, 0)
end)
test("space and Unicode path framing", function()
	local path = "/home/日本語/ leading and trailing spaces "
	state.query.stdout = path .. "\r\n" .. second -- CRLF plus unterminated final line.
	state.picker.stdout = path .. "\r\n"
	run()
	equal(state.input, path .. "\n" .. second .. "\n")
	equal(state.emitted[1].args[1], path)
end)
test("empty history leaves UI untouched", function()
	state.query.stdout = ""
	run()
	no_navigation()
	equal(#state.commands, 1)
	equal(state.hides, 0)
	equal(#state.notifications, 0)
end)

for _, code in ipairs { 1, 130 } do
	test("cancel status " .. code .. " ignores stdout", function()
		state.picker = result(code, first .. "\n")
		run()
		no_navigation()
		equal(#state.notifications, 0)
	end)
	test("early cancel status " .. code .. " ignores broken pipe", function()
		state.picker = result(code, first .. "\n")
		state.write_error = true
		run()
		no_navigation()
		equal(#state.notifications, 0)
	end)
end
for _, stdout in ipairs { "", "\n", "\r\n" } do
	test("empty successful output " .. #stdout, function()
		state.picker.stdout = stdout
		run()
		no_navigation()
		equal(#state.notifications, 0)
	end)
end

for _, code in ipairs { 2, 127, -9 } do
	test("unexpected picker status " .. code, function()
		state.picker = result(code, first .. "\n")
		run()
		error_contains("status " .. code)
	end)
end
test("signal or missing picker status", function()
	state.picker.status = { success = false }
	run()
	error_contains("status nil")
end)
test("missing picker status object", function()
	state.picker.status = nil
	run()
	error_contains("status nil")
end)
test("inconsistent success status rejected", function()
	state.picker.status = { code = 0, success = false }
	run()
	error_contains("status 0")
end)

for _, stdout in ipairs { first .. "\n\n", first .. "\n" .. second, first .. "\0", first .. "\r", "\255" } do
	test("malformed picker stdout " .. #stdout, function()
		state.picker.stdout = stdout
		run()
		error_contains("exactly one raw UTF-8 path")
	end)
end
test("decorated or foreign path", function()
	state.picker.stdout = "10.0 " .. first .. "\n"
	run()
	error_contains("did not match a supplied directory")
end)
for _, flag in ipairs { "missing_directory", "regular_file", "cha_exception" } do
	test("selected path check " .. flag, function()
		state[flag] = true
		run()
		error_contains(flag == "cha_exception" and "metadata exception" or "not a directory")
	end)
end

for _, flag in ipairs { "spawn_error", "spawn_exception", "wait_error", "wait_exception", "write_error", "write_exception", "flush_error", "flush_exception" } do
	test("picker I/O failure " .. flag, function()
		state[flag] = true
		run()
		error_contains(flag:find("spawn") and "PATH" or (flag:find("wait") and "output" or "stdin"))
		equal(state.hides, 1)
		if flag:find("exception") and not flag:find("spawn") then
			equal(state.killed, true)
			equal(state.reaped, true)
		end
	end)
end
test("cleanup exceptions cannot prevent restoration", function()
	state.write_exception, state.cleanup_exception = true, true
	run()
	error_contains("write exception")
	equal(state.killed, true)
	equal(state.reaped, true)
end)
test("picker constructor exception after hide", function()
	state.constructor_exception = "custom-picker"
	run()
	error_contains("PATH")
	equal(state.hides, 1)
end)

for _, flag in ipairs { "query_error", "query_exception" } do
	test("query I/O failure " .. flag, function()
		state[flag] = true
		run()
		error_contains("install zoxide")
		equal(state.hides, 0)
	end)
end
test("query status failure includes diagnostics", function()
	state.query = result(1, "")
	state.query.stderr = "database could not be opened"
	run()
	error_contains("database could not be opened")
	equal(#state.commands, 1)
end)
test("query signal status", function()
	state.query.status = { success = false }
	run()
	error_contains("status nil")
end)
for _, stdout in ipairs { "\n", first .. "\n\n", first .. "\0", "\255", "/bad\rcandidate\n" } do
	test("invalid candidate framing " .. #stdout, function()
		state.query.stdout = stdout
		run()
		error_contains("Zoxide returned")
		equal(state.hides, 0)
	end)
end
test("newline cwd unsupported", function()
	cx.tab.current.cwd = Url("/embedded\nnewline")
	run()
	error_contains("CR/LF")
	equal(#state.commands, 0)
end)
test("missing current API tab", function()
	plugin:entry({})
	error_contains("upgrade Yazi")
end)
test("missing current API context", function()
	cx = {}
	run()
	error_contains("cx.tab")
end)
test("hide exception", function()
	state.hide_exception = true
	run()
	error_contains("hide exception")
end)
test("emit exception after restoration", function()
	state.emit_exception = true
	run()
	error_contains("navigate the invoking tab")
end)

print("zoxide-picker.yazi: " .. tests .. " mock cases passed")
