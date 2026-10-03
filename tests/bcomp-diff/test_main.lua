-- Resolve the plugin relative to this script so the test runs from any cwd.
local script_dir = (arg[0] or ""):gsub("\\", "/"):match("^(.*)/[^/]*$") or "."
local source = arg[1] or (script_dir .. "/../../bcomp-diff.yazi/main.lua")

local notifications = {}
local emitted = {}

ya = {
	sync = function(fn)
		return fn
	end,
	notify = function(notification)
		notifications[#notifications + 1] = notification
	end,
	emit = function(name, args)
		emitted[#emitted + 1] = { name = name, args = args }
	end,
}

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
	emitted = {}
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

-- 0 selected: do not emit, explain why.
reset()
run({})
assert_equal(#emitted, 0, "0 selected emit count")
assert_notification("warn", "0 selected")

-- 1 selected: do not emit, explain why.
reset()
run({ file([[C:\a.txt]]) })
assert_equal(#emitted, 0, "1 selected emit count")
assert_notification("warn", "only 1 selected")

-- 3 selected: do not emit, explain why.
reset()
run({ file([[C:\a.txt]]), file([[C:\b.txt]]), file([[C:\c.txt]]) })
assert_equal(#emitted, 0, "3 selected emit count")
assert_notification("warn", "3 selected")

-- 4 selected: still rejected.
reset()
run({ file([[C:\a.txt]]), file([[C:\b.txt]]), file([[C:\c.txt]]), file([[C:\d.txt]]) })
assert_equal(#emitted, 0, "4 selected emit count")
assert_notification("warn", "4 selected")

-- Exactly 2 selected: run Yazi's shell command with the original template, so
-- Yazi expands and quotes %s1 and %s2 itself.
reset()
run({ file([[C:\work\a.txt]]), file([[C:\work\b.txt]]) })
assert_equal(#notifications, 0, "success notification count")
assert_equal(#emitted, 1, "2 selected emit count")
assert_equal(emitted[1].name, "shell", "emitted command")
assert_equal(emitted[1].args[1], "BComp.exe %s1 %s2", "shell command line")
assert_equal(#emitted[1].args, 1, "shell positional argument count")
assert_equal(emitted[1].args.orphan, true, "shell command is detached")

-- No tab available is reported.
reset()
cx = { tabs = { idx = 1 } }
plugin.entry()
assert_equal(#emitted, 0, "no tab emit count")
assert_notification("warn", "Could not read")

print("bcomp-diff.yazi tests passed")
