--- @since 26.5.6
--- Tested with Yazi 26.8.15; older direct selected-URL values remain supported.

local program = "BComp.exe"

local messages = {
	title = "Beyond Compare",
	none_selected = "Select exactly two files to compare (0 selected).",
	one_selected = "Select exactly two files to compare (only 1 selected).",
	too_many_selected = "Select exactly two files to compare (%d selected).",
	selected_unavailable = "Could not read the selected files.",
	launch_failed = "Could not launch Beyond Compare: ",
	process_unavailable = "Could not start the Beyond Compare process.",
}

local function notify(level, content)
	ya.notify {
		title = messages.title,
		content = content,
		timeout = level == "error" and 7 or 5,
		level = level,
	}
end

local function resolve_path(entry)
	if not entry then
		return nil
	end

	-- Yazi 26.8.15 returns File entries from tab.selected. Older versions
	-- returned URL-like entries directly; keep both representations working.
	local url = entry.url or entry
	return tostring(url)
end

-- Returns the selected paths in the active tab, or nil plus a message when
-- the selection is not exactly two entries.
local get_selected_paths = ya.sync(function()
	local tab = cx.tabs[cx.tabs.idx]
	if not tab then
		return nil, messages.selected_unavailable
	end

	local paths = {}
	for _, entry in pairs(tab.selected or {}) do
		local path = resolve_path(entry)
		if not path then
			return nil, messages.selected_unavailable
		end
		paths[#paths + 1] = path
	end

	if #paths == 0 then
		return nil, messages.none_selected
	end
	if #paths == 1 then
		return nil, messages.one_selected
	end
	if #paths > 2 then
		return nil, messages.too_many_selected:format(#paths)
	end

	return paths, nil
end)

local function launch_diff(left, right)
	-- Paths are separate arguments, so spaces never depend on shell quoting.
	return Command(program)
		:arg { left, right }
		:spawn()
end

local function entry()
	local paths, selection_error = get_selected_paths()
	if not paths then
		notify("warn", selection_error)
		return
	end

	-- Protect the plugin from API/runtime errors while starting an external
	-- process.
	local ok, child, launch_error = pcall(launch_diff, paths[1], paths[2])
	if not ok then
		notify("error", messages.launch_failed .. tostring(child))
		return
	end

	if launch_error then
		notify("error", messages.launch_failed .. tostring(launch_error))
		return
	end

	if not child then
		notify("error", messages.process_unavailable)
	end
end

return {
	entry = entry,
}
