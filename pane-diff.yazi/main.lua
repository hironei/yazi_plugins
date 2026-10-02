--- @since 26.5.6
--- Tested with Yazi 26.8.15; older direct selected-URL values remain supported.

local messages = {
	title = "Pane diff",
	wrong_tab_count =
		"比較には2つのタブが必要です。split-tabsを有効にしてください。",
	missing_target = "カーソル位置に比較対象がありません。",
	multiple_selection = "各ペインの選択対象は1つにしてください。",
	tab_unavailable = "比較対象のタブを取得できませんでした。",
	selected_unavailable = "選択対象を取得できませんでした。",
	tool_unavailable = "GitのDiffツール設定を取得できませんでした: ",
	tool_not_configured = "GitにDiffツールが設定されていません。",
	process_unavailable = "Diffツールのプロセスを開始できませんでした。",
	launch_failed = "Diffツールを起動できませんでした: ",
	wait_failed = "Diffツールの実行状態を取得できませんでした: ",
	process_failed = "Diffツールが異常終了しました: ",
}

local function notify(level, content)
	ya.notify {
		title = messages.title,
		content = content,
		timeout = level == "error" and 7 or 5,
		level = level,
	}
end

local function count_selected(selected)
	local count = 0

	for _ in pairs(selected or {}) do
		count = count + 1
	end

	return count
end

local function resolve_url(entry)
	if not entry then
		return nil
	end

	-- Yazi 26.8.15 returns File entries from tab.selected. Older versions
	-- returned URL-like entries directly; keep both representations working.
	return entry.url or entry
end

local function resolve_path(entry)
	local url = resolve_url(entry)
	if not url then
		return nil
	end

	return tostring(url)
end

local function get_single_selected(selected)
	for _, entry in pairs(selected or {}) do
		return entry
	end

	return nil
end

local function get_target_from_tab(tab)
	local selected_count = count_selected(tab.selected)

	if selected_count == 1 then
		local path = resolve_path(get_single_selected(tab.selected))
		if not path then
			return nil, messages.selected_unavailable
		end
		return path, nil
	end

	if selected_count > 1 then
		return nil, messages.multiple_selection
	end

	local path = resolve_path(tab.current and tab.current.hovered)
	if not path then
		return nil, messages.missing_target
	end
	return path, nil
end

local get_compare_targets = ya.sync(function()
	if #cx.tabs ~= 2 then
		return nil, nil, messages.wrong_tab_count
	end

	local active_index = cx.tabs.idx
	local other_index = active_index == 1 and 2 or 1
	local active_tab = cx.tabs[active_index]
	local other_tab = cx.tabs[other_index]

	if not active_tab or not other_tab then
		return nil, nil, messages.tab_unavailable
	end

	local active_path, active_error = get_target_from_tab(active_tab)
	if not active_path then
		return nil, nil, "アクティブペイン: " .. tostring(active_error)
	end

	local other_path, other_error = get_target_from_tab(other_tab)
	if not other_path then
		return nil, nil, "反対側ペイン: " .. tostring(other_error)
	end

	return active_path, other_path, nil
end)

local function trim(value)
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function read_git_config(key)
	local output, err = Command("git")
		:arg { "config", "--get", "--default=", key }
		:output()

	if err then
		return nil, tostring(err)
	end

	if not output or type(output.stdout) ~= "string" then
		return nil, "Gitの設定出力を取得できませんでした"
	end

	return trim(output.stdout), nil
end

local function get_diff_tool()
	local tool, tool_error = read_git_config("diff.tool")
	if tool_error then
		return nil, messages.tool_unavailable .. tool_error
	end

	if not tool or tool == "" then
		return nil, messages.tool_not_configured
	end

	local path, path_error = read_git_config("difftool." .. tool .. ".path")
	if path_error then
		return nil, messages.tool_unavailable .. path_error
	end

	-- Git uses the configured tool name when no explicit path is set and
	-- expects that executable to be available through PATH.
	return path ~= "" and path or tool, nil
end

local function launch_diff(tool, left, right)
	return Command(tool)
		:arg { left, right }
		:spawn()
end

local function monitor_diff(child)
	local ok, status, wait_error = pcall(function()
		return child:wait()
	end)

	if not ok then
		notify("error", messages.wait_failed .. tostring(status))
		return
	end

	if wait_error then
		notify("error", messages.wait_failed .. tostring(wait_error))
		return
	end

	if status and not status.success then
		notify("error", messages.process_failed .. "終了コード " .. tostring(status.code))
	end
end

local function entry()
	local active_path, other_path, target_error = get_compare_targets()
	if target_error then
		notify("warn", target_error)
		return
	end

	local diff_tool, tool_error = get_diff_tool()
	if tool_error then
		notify("error", tool_error)
		return
	end

	-- Protect the plugin from API/runtime errors while starting an external
	-- process. Paths are still passed as separate arguments to Command.
	local ok, child, launch_error = pcall(launch_diff, diff_tool, active_path, other_path)
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
		return
	end

	monitor_diff(child)
end

return {
	entry = entry,
}
