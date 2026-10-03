--- @since 26.5.6
--- Validates the selection, then runs Yazi's own `shell` command.

-- %s1 and %s2 are expanded and quoted by Yazi itself, the same path as
-- `run = 'shell -- BComp.exe %s1 %s2'` in keymap.toml.
-- orphan = true detaches the process so Yazi does not keep it as a background
-- task after Beyond Compare exits.
local shell_command = "BComp.exe %s1 %s2"

local messages = {
	title = "Beyond Compare",
	none_selected = "Select exactly two files to compare (0 selected).",
	one_selected = "Select exactly two files to compare (only 1 selected).",
	too_many_selected = "Select exactly two files to compare (%d selected).",
	selected_unavailable = "Could not read the selected files.",
}

local function notify(level, content)
	ya.notify {
		title = messages.title,
		content = content,
		timeout = 5,
		level = level,
	}
end

-- Returns the number of selected entries in the active tab, or nil when the
-- tab is unavailable.
local get_selected_count = ya.sync(function()
	local tab = cx.tabs[cx.tabs.idx]
	if not tab then
		return nil
	end

	local count = 0
	for _ in pairs(tab.selected or {}) do
		count = count + 1
	end
	return count
end)

local function entry()
	local count = get_selected_count()
	if not count then
		notify("warn", messages.selected_unavailable)
	elseif count == 0 then
		notify("warn", messages.none_selected)
	elseif count == 1 then
		notify("warn", messages.one_selected)
	elseif count > 2 then
		notify("warn", messages.too_many_selected:format(count))
	else
		ya.emit("shell", { shell_command, orphan = true })
	end
end

return {
	entry = entry,
}
