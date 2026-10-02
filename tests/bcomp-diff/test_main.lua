-- Resolve the plugin relative to this script so the test runs from any cwd.
local script_dir = (arg[0] or ""):gsub("\\", "/"):match("^(.*)/[^/]*$") or "."
local source = arg[1] or (script_dir .. "/../../bcomp-diff.yazi/main.lua")

local notifications = {}
local launched = {}
local spawn_result = { child = {}, err = nil }

ya = {
	sync = function(fn)
		return fn
	end,
	notify = function(notification)
		notifications[#notifications + 1] = notification
	end,
}

local command = {}
function command:arg(args)
	self.args = args
	return self
end

function command:spawn()
	if spawn_result.raise then
		error(spawn_result.raise)
	end
	launched[#launched + 1] = {
		program = self.program,
		args = self.args,
	}
	return spawn_result.child, spawn_result.err
end

function Command(program)
	return setmetatable({ program = program }, { __index = command })
end

local plugin = assert(loadfile(source))()

local function url(path)
	return setmetatable({ path = path }, {
		__tostring = function(value)
			return value.path
		end,
	})
end

-- Yazi 26.8.15 selected entries are File objects carrying a .url.
local function file(path)
	return { url = url(path) }
end

local function reset()
	notifications = {}
	launched = {}
	spawn_result = { child = {}, err = nil }
end

local function run(selected)
	cx = { tabs = { idx = 1, { selected = selected, current = {} } } }
	plugin.entry()
end

local function assert_equal(actual, expected, message)
	assert(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assert_notification(level, fragment)
	assert_equal(#notifications, 1, "notification count")
	assert_equal(notifications[1].level, level, "notification level")
	assert(notifications[1].content:find(fragment, 1, true), "notification did not contain: " .. fragment)
end

-- 0 selected: do not launch, explain why.
reset()
run({})
assert_equal(#launched, 0, "0 selected launch count")
assert_notification("warn", "0 selected")

-- 1 selected: do not launch, explain why.
reset()
run({ file([[C:\a.txt]]) })
assert_equal(#launched, 0, "1 selected launch count")
assert_notification("warn", "only 1 selected")

-- 3 selected: do not launch, explain why.
reset()
run({ file([[C:\a.txt]]), file([[C:\b.txt]]), file([[C:\c.txt]]) })
assert_equal(#launched, 0, "3 selected launch count")
assert_notification("warn", "3 selected")

-- 4 selected: still rejected.
reset()
run({ file([[C:\a.txt]]), file([[C:\b.txt]]), file([[C:\c.txt]]), file([[C:\d.txt]]) })
assert_equal(#launched, 0, "4 selected launch count")
assert_notification("warn", "4 selected")

-- Exactly 2 selected: launch BComp.exe with both paths as separate arguments.
reset()
run({ file([[C:\work\a.txt]]), file([[C:\work\b.txt]]) })
assert_equal(#notifications, 0, "success notification count")
assert_equal(#launched, 1, "2 selected launch count")
assert_equal(launched[1].program, "BComp.exe", "program")
assert_equal(#launched[1].args, 2, "argument count")
assert_equal(launched[1].args[1], [[C:\work\a.txt]], "first path")
assert_equal(launched[1].args[2], [[C:\work\b.txt]], "second path")

-- Windows paths with spaces and non-ASCII characters stay single arguments
-- with no quoting added.
reset()
run({ file([[C:\Program Files\My Docs\left file.txt]]), file([[D:\work (copy)\右 側.txt]]) })
assert_equal(#launched, 1, "spaces launch count")
assert_equal(#launched[1].args, 2, "spaces argument count")
assert_equal(launched[1].args[1], [[C:\Program Files\My Docs\left file.txt]], "path with spaces")
assert_equal(launched[1].args[2], [[D:\work (copy)\右 側.txt]], "path with spaces and non-ASCII")

-- Older Yazi versions return URL-like selected values directly.
reset()
run({ url([[C:\old one.txt]]), url([[C:\old two.txt]]) })
assert_equal(launched[1].args[1], [[C:\old one.txt]], "direct URL first path")
assert_equal(launched[1].args[2], [[C:\old two.txt]], "direct URL second path")

-- Spawn returning an error is reported.
reset()
spawn_result = { child = nil, err = "BComp.exe not found" }
run({ file([[C:\a.txt]]), file([[C:\b.txt]]) })
assert_equal(#launched, 1, "failed launch attempt count")
assert_notification("error", "BComp.exe not found")

-- Spawn raising a runtime error is reported, not propagated.
reset()
spawn_result = { raise = "spawn exploded" }
run({ file([[C:\a.txt]]), file([[C:\b.txt]]) })
assert_equal(#launched, 0, "raised spawn launch count")
assert_notification("error", "spawn exploded")

-- Spawn returning neither child nor error is reported.
reset()
spawn_result = { child = nil, err = nil }
run({ file([[C:\a.txt]]), file([[C:\b.txt]]) })
assert_notification("error", "Could not start")

print("bcomp-diff.yazi tests passed")
