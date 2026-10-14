local M = {}

local function notify(content)
	ya.notify { title = "File picker", content = content, timeout = 8, level = "error" }
end

local function validate_config(opts)
	if type(opts) ~= "table" or type(opts.command) ~= "string"
		or not opts.command:find("%S") or opts.command:find("[%z\r\n]") then
		return nil, "Set a nonempty executable in require(\"file-picker\"):setup { command = ..., args = {...} } in init.lua."
	end
	if type(opts.args) ~= "table" then
		return nil, "Set args to an argv array of strings in file-picker setup; use {} for no arguments."
	end

	local count = 0
	for key in pairs(opts.args) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return nil, "Picker args must be a consecutive argv array, without named keys or gaps."
		end
		count = count + 1
	end
	local args = {}
	for index = 1, count do
		local value = opts.args[index]
		if type(value) ~= "string" or value:find("%z") then
			return nil, "Picker args must be consecutive strings without NUL bytes."
		end
		args[index] = value
	end
	return { command = opts.command, args = args }
end

function M:setup(opts)
	-- Store main-context state. Async entry reads it through ya.sync, never
	-- through its separately loaded module table. Copy argv to own the config.
	self.config, self.config_error = validate_config(opts)
	return self.config ~= nil, self.config_error
end

local snapshot = ya.sync(function(self, has_job_tab)
	if has_job_tab then
		local cwd = cx.tab and cx.tab.current and cx.tab.current.cwd
		return self.config, self.config_error, cwd and tostring(cwd)
	end
	-- Older jobs have no tab identity. Capture the active tab's directory and
	-- ID in one synchronous snapshot before any asynchronous process work.
	local active = cx.active
	local cwd = active and active.current and active.current.cwd
	return self.config, self.config_error, cwd and tostring(cwd), active and active.id
end)

local function fail(message)
	error(message, 0)
end

local function candidates_from(stdout)
	if stdout == "" then
		return "", {}
	end
	-- NUL framing from rg makes embedded newline names detectable before
	-- converting to the selector's newline-delimited protocol.
	if not utf8.len(stdout) or stdout:sub(-1) ~= "\0" then
		fail("rg returned invalid UTF-8 or an unterminated NUL-delimited path list.")
	end
	local paths, members = {}, {}
	for path in stdout:gmatch("(.-)%z") do
		if path == "" or path:find("[\r\n]") then
			fail("rg returned a malformed path list; blank paths and embedded CR/LF names are unsupported.")
		end
		paths[#paths + 1] = path
		members[path] = true
	end
	return table.concat(paths, "\n") .. "\n", members
end

local function selection_from(stdout, members, cwd)
	-- Strip one record terminator only. A second line is invalid, even if
	-- blank; whitespace is part of a file name and must survive.
	local target = stdout:gsub("\r?\n$", "")
	if target == "" then
		return nil
	end
	if target:find("[%z\r\n]") or not utf8.len(target) then
		fail("Picker stdout must contain exactly one raw UTF-8 path, with at most one LF or CRLF terminator; send UI and diagnostics to the terminal/stderr.")
	end
	if not members[target] then
		fail("Picker stdout did not match a supplied file path; disable scores, decorations, query lines, and path conversion.")
	end
	local url = Url(cwd):join(target)
	local cha, err = fs.cha(url, true)
	if not cha or not cha.is_file then
		fail("The selected file no longer exists or is not a regular file" .. (err and (": " .. tostring(err)) or "."))
	end
	return tostring(url)
end

function M:entry(job)
	local permit, child
	local target_tab = job and job.tab
	local phase = "read picker configuration"
	local ok, target = pcall(function()
		local config, config_error, cwd, legacy_tab = snapshot(target_tab ~= nil)
		if not config then
			fail(config_error or "Configure require(\"file-picker\"):setup { command = ..., args = {...} } in init.lua; there is no default picker.")
		end
		if target_tab == nil then
			target_tab = legacy_tab
		end
		if target_tab == nil then
			fail("Could not identify the invoking tab; Yazi must expose job.tab or cx.active.id.")
		end
		if not cwd or cwd == "" then
			fail("Could not read the invoking tab's directory from cx.tab or cx.active.")
		end
		if cwd:find("[\r\n]") then
			fail("Directories containing CR/LF cannot be represented by the newline-delimited picker protocol.")
		end

		phase = "enumerate files; install rg (ripgrep) and make it available in Yazi's PATH"
		local output, err = Command("rg")
			:arg { "--files", "--null", "--color", "never", "--no-config" }
			:cwd(cwd)
			:stdin(Command.NULL)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
		if not output then
			fail("Could not run rg: " .. tostring(err))
		end
		if output.status and output.status.code == 1 and not output.status.success and output.stdout == "" and (output.stderr or "") == "" then
			return nil -- rg reports a clean no-files result with status 1.
		end
		if not output.status or not output.status.success or output.status.code ~= 0 then
			fail("rg file enumeration failed (status " .. tostring(output.status and output.status.code) .. "): " .. (output.stderr or ""))
		end
		local input, members = candidates_from(output.stdout)
		if input == "" then
			return nil -- No files: leave the UI alone and do not launch a picker.
		end

		phase = "hide Yazi's UI"
		permit = ui.hide()
		phase = "start configured picker; check setup.command, installation, and Yazi's PATH"
		child, err = Command(config.command)
			:arg(config.args)
			:cwd(cwd)
			:stdin(Command.PIPED)
			:stdout(Command.PIPED)
			:stderr(Command.INHERIT)
			:spawn()
		if not child then
			fail("Could not launch configured picker: " .. tostring(err))
		end

		phase = "write file candidates to picker stdin"
		local written, write_error = child:write_all(input)
		local flushed, flush_error
		if written then
			flushed, flush_error = child:flush()
		end

		phase = "read configured picker output and status"
		-- Yazi buffers stdin. Flush before wait_with_output closes it and sends
		-- EOF, then drains stdout while waiting. Do not leave EOF to Lua GC.
		output, err = child:wait_with_output()
		child = nil -- wait_with_output consumes the Child userdata.
		if not output then
			fail("Could not read configured picker output: " .. tostring(err))
		end
		local status = output.status
		if status and (status.code == 1 or status.code == 130) then
			return nil -- Includes early cancellation/broken pipe; never use stdout.
		end
		if not status or status.code ~= 0 or not status.success then
			fail("Configured picker exited unexpectedly (status " .. tostring(status and status.code) .. "); check picker arguments and terminal support.")
		end
		if not written or not flushed then
			fail("Could not send all candidates to picker stdin: " .. tostring(write_error or flush_error))
		end
		phase = "validate selected file"
		return selection_from(output.stdout, members, cwd)
	end)

	-- A thrown API error can leave an owned process. Stop/reap it before
	-- restoring Yazi; cleanup errors must not prevent dropping the permit.
	if child then
		pcall(function() child:start_kill() end)
		pcall(function() child:wait() end)
	end
	if permit then
		local restored, restore_error = pcall(function() permit:drop() end)
		if not restored then
			notify("Could not restore Yazi's UI: " .. tostring(restore_error))
			return
		end
	end
	if not ok then
		notify("Could not " .. phase .. ": " .. tostring(target))
	elseif target then
		local emitted, emit_error = pcall(function()
			ya.emit("reveal", { target, raw = true, tab = target_tab })
		end)
		if not emitted then
			notify("Could not reveal the file in the invoking tab: " .. tostring(emit_error))
		end
	end
end

return M
