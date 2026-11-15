-- Integration test: the config starts cleanly and its main features work.
-- Run from the config folder:
--   nvim --headless -l tests/startup_test.lua
-- Exits 0 when every check passes, 1 otherwise.
--
-- Drives a second Neovim (real config, real plugins, real language servers) over RPC,
-- opens sample files in a temp folder, and checks:
--   * the config files no longer use names that the plugins or Neovim deprecated
--   * each language gets its language server exactly once, and no unwanted server runs
--   * remapped keys work: ]d, gd, Visual J and K
--   * a Python problem is reported once, not by two tools
--   * completion shortens long suggestions and still shows Tailwind colors
--   * every keymap the config defines has a description (which-key shows it)
--   * no warning or error shows up in :messages, and :checkhealth vim.deprecated is clean

local STEP_PAUSE_MS = 150
local STARTUP_TIMEOUT_MS = 10000
local LSP_TIMEOUT_MS = 20000
local CONFIG_DIR = vim.fn.getcwd()

local SAMPLES = {
	{ file = "sample.lua", text = { "local x = 1", "print(x)" }, servers = { "lua_ls" } },
	{ file = "sample.ts", text = { "const x: number = 1;", "console.log(x);" }, servers = { "ts_ls" } },
	-- the unused import gives the Python check something to report
	{ file = "sample.py", text = { "import os", "", "x = 1", "print(x)" }, servers = { "ruff" } },
	{ file = "sample.html", text = { "<div>hi</div>" }, servers = { "html" } },
	{ file = "sample.css", text = { ".a { color: red; }" }, servers = { "cssls" } },
}

-- Servers that must never start: pylsp duplicates ruff, stylua is a formatter run by conform.
local UNWANTED_SERVERS = { "pylsp", "stylua" }

local BAD_MESSAGE_PATTERNS = {
	"deprecated",
	"[Ee]rror",
	"quit with exit code",
	"must have",
	"[Ww]arning",
}

-- Old names that Neovim 0.11 or the installed plugin versions deprecated.
local DEPRECATED_NAMES = {
	{ pattern = 'require%("lspconfig"%)', reason = "nvim-lspconfig framework (use vim.lsp.config)" },
	{ pattern = "%.setup%(%{%s*capabilities", reason = "lspconfig.<server>.setup (use vim.lsp.config)" },
	{ pattern = "sign_define", reason = "diagnostic signs (use vim.diagnostic.config)" },
	{ pattern = "diagnostic%.goto_", reason = "vim.diagnostic.goto_next/prev (use vim.diagnostic.jump)" },
	{ pattern = "vim%.highlight%.", reason = "vim.highlight (renamed to vim.hl)" },
	{ pattern = "next_hunk", reason = "gitsigns next_hunk (use nav_hunk)" },
	{ pattern = "prev_hunk", reason = "gitsigns prev_hunk (use nav_hunk)" },
	{ pattern = "undo_stage_hunk", reason = "gitsigns undo_stage_hunk (stage_hunk toggles)" },
	{ pattern = "lsp_fallback", reason = "conform lsp_fallback (use lsp_format)" },
	{ pattern = "auto_restore_enabled", reason = "auto-session (renamed to auto_restore)" },
	{ pattern = "auto_session_suppress_dirs", reason = "auto-session (renamed to suppressed_dirs)" },
	{ pattern = '"williamboman/', reason = "mason moved to mason-org/" },
}

-- Runs before init.lua (--cmd) and records who calls vim.keymap.set, with the desc it passes.
local RECORD_KEYMAPS = table.concat({
	"_G.__startup_test_keymaps = {}",
	"local set = vim.keymap.set",
	"vim.keymap.set = function(mode, lhs, rhs, opts)",
	"local info = debug.getinfo(2, 'Sl')",
	"table.insert(_G.__startup_test_keymaps, { lhs = lhs, desc = opts and opts.desc or nil, source = info.source, line = info.currentline })",
	"return set(mode, lhs, rhs, opts)",
	"end",
}, " ")

local failures = 0

local function check(ok, name, detail)
	if ok then
		io.write(("[PASS] %s\n"):format(name))
	else
		failures = failures + 1
		io.write(("[FAIL] %s: %s\n"):format(name, detail or ""))
	end
end

local function start_editor(cwd)
	local channel = vim.fn.jobstart(
		{ "nvim", "--embed", "--headless", "--cmd", "lua " .. RECORD_KEYMAPS },
		{ rpc = true, cwd = cwd }
	)
	assert(channel > 0, "could not start the embedded Neovim (jobstart returned " .. channel .. ")")
	local ready = vim.wait(STARTUP_TIMEOUT_MS, function()
		return (pcall(vim.rpcrequest, channel, "nvim_eval", "1"))
	end, 100)
	assert(ready, "embedded Neovim did not answer within " .. STARTUP_TIMEOUT_MS .. " ms")
	return channel
end

local function press(channel, keys)
	vim.rpcrequest(channel, "nvim_input", keys)
	vim.wait(STEP_PAUSE_MS)
end

local function remote_lua(channel, code, args)
	return vim.rpcrequest(channel, "nvim_exec_lua", code, args or {})
end

local function buffer_lines(channel)
	return vim.rpcrequest(channel, "nvim_buf_get_lines", 0, 0, -1, false)
end

local function client_names(channel)
	return remote_lua(
		channel,
		[[
		local names = {}
		for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do table.insert(names, c.name) end
		table.sort(names)
		return names
	]]
	)
end

local function count(list, value)
	local n = 0
	for _, item in ipairs(list) do
		if item == value then
			n = n + 1
		end
	end
	return n
end

local function write_samples(dir)
	for _, sample in ipairs(SAMPLES) do
		vim.fn.writefile(sample.text, dir .. "/" .. sample.file)
	end
end

local function check_config_names()
	local files = vim.fn.globpath(CONFIG_DIR, "lua/**/*.lua", false, true)
	for _, entry in ipairs(DEPRECATED_NAMES) do
		local hits = {}
		for _, path in ipairs(files) do
			for number, line in ipairs(vim.fn.readfile(path)) do
				local code = line:gsub("%-%-.*$", "")
				if code:match(entry.pattern) then
					table.insert(hits, ("%s:%d"):format(vim.fn.fnamemodify(path, ":."), number))
				end
			end
		end
		check(#hits == 0, "config does not use " .. entry.reason, table.concat(hits, ", "))
	end
end

local function check_language_servers(channel)
	for _, sample in ipairs(SAMPLES) do
		vim.rpcrequest(channel, "nvim_command", "edit " .. sample.file)
		local names = {}
		vim.wait(LSP_TIMEOUT_MS, function()
			names = client_names(channel)
			for _, server in ipairs(sample.servers) do
				if count(names, server) == 0 then
					return false
				end
			end
			return true
		end, 250)
		-- give a second, duplicate client time to show up if one is going to
		vim.wait(1500)
		names = client_names(channel)

		local shown = table.concat(names, ",")
		for _, server in ipairs(sample.servers) do
			check(
				count(names, server) == 1,
				("%s runs %s exactly once"):format(sample.file, server),
				("clients=%s"):format(shown)
			)
		end
		for _, server in ipairs(UNWANTED_SERVERS) do
			check(
				count(names, server) == 0,
				("%s does not run %s"):format(sample.file, server),
				("clients=%s"):format(shown)
			)
		end
	end
end

local function use_remapped_keys(channel)
	vim.rpcrequest(channel, "nvim_command", "edit sample.lua")
	-- yank highlight (TextYankPost autocmd)
	press(channel, "yy")
	-- diagnostic jump keys need a diagnostic to move to
	remote_lua(
		channel,
		[[
		local ns = vim.api.nvim_create_namespace("startup_test")
		vim.diagnostic.set(ns, 0, {
			{ lnum = 1, col = 0, message = "test diagnostic", severity = vim.diagnostic.severity.WARN },
		})
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	]]
	)
	press(channel, "]d")
	local line_after_next = remote_lua(channel, "return vim.api.nvim_win_get_cursor(0)[1]")
	check(line_after_next == 2, "]d moves to the next diagnostic", ("cursor line=%s"):format(line_after_next))
	press(channel, "<Esc>")
	press(channel, "[d")
	press(channel, "<Esc>")

	-- gd goes through Telescope's LSP picker (the 0.1.x picker warned on Neovim 0.11).
	-- Clear only this test's diagnostic: a bare reset() would also wipe the servers' ones.
	remote_lua(
		channel,
		[[
		vim.diagnostic.reset(vim.api.nvim_create_namespace("startup_test"))
		vim.api.nvim_win_set_cursor(0, { 2, 6 })
	]]
	)
	press(channel, "gd")
	vim.wait(2000)
	local line_after_gd = remote_lua(channel, "return vim.api.nvim_win_get_cursor(0)[1]")
	check(line_after_gd == 1, "gd jumps to where x is defined", ("cursor line=%s"):format(line_after_gd))

	-- Visual-mode J and K move the selected lines
	remote_lua(channel, "vim.api.nvim_win_set_cursor(0, { 1, 0 })")
	press(channel, "V")
	press(channel, "J")
	local after_down = buffer_lines(channel)
	press(channel, "K")
	local after_up = buffer_lines(channel)
	press(channel, "<Esc>")
	check(
		after_down[1] == "print(x)" and after_down[2] == "local x = 1",
		"Visual J moves the selected line down",
		table.concat(after_down, " / ")
	)
	check(
		after_up[1] == "local x = 1" and after_up[2] == "print(x)",
		"Visual K moves the selected line up",
		table.concat(after_up, " / ")
	)
end

local function check_no_duplicate_diagnostics(channel)
	vim.rpcrequest(channel, "nvim_command", "edit sample.py")
	vim.wait(LSP_TIMEOUT_MS, function()
		return remote_lua(channel, "return #vim.diagnostic.get(0)") > 0
	end, 250)
	-- give a second reporter, if there is one, time to add its copy
	vim.wait(3000)
	local diagnostics = remote_lua(
		channel,
		[[
		local rows = {}
		for _, d in ipairs(vim.diagnostic.get(0)) do
			table.insert(rows, { key = d.lnum .. ":" .. d.col .. ":" .. tostring(d.code), source = tostring(d.source) })
		end
		return rows
	]]
	)
	check(#diagnostics > 0, "sample.py reports the unused import", "no diagnostics")

	local sources_by_problem = {}
	for _, d in ipairs(diagnostics) do
		sources_by_problem[d.key] = sources_by_problem[d.key] or {}
		table.insert(sources_by_problem[d.key], d.source)
	end
	local duplicates = {}
	for problem, sources in pairs(sources_by_problem) do
		if #sources > 1 then
			table.insert(duplicates, problem .. " reported by " .. table.concat(sources, " and "))
		end
	end
	check(#duplicates == 0, "sample.py shows each problem once", table.concat(duplicates, "; "))
end

local function check_completion_format(channel)
	-- nvim-cmp and its formatters load on the first InsertEnter
	vim.rpcrequest(channel, "nvim_command", "enew!")
	press(channel, "i")
	vim.wait(500)
	press(channel, "<Esc>")
	local result = remote_lua(
		channel,
		[[
		local format = require("cmp.config").get().formatting.format
		local entry = { source = { name = "nvim_lsp" }, get_completion_item = function() return {} end }
		local long = string.rep("a", 80)
		local plain = format(entry, { word = long, abbr = long, kind = "Function" })
		local color = format(entry, { word = "bg-red-500", abbr = "bg-red-500", kind = "Color" })
		return { abbr_chars = vim.fn.strchars(plain.abbr), color_kind = color.kind, color_hl = color.kind_hl_group or "" }
	]]
	)
	check(
		result.abbr_chars == 53,
		"completion shortens a long suggestion to 50 characters plus ...",
		("shown length=%d"):format(result.abbr_chars)
	)
	check(
		result.color_kind == "XX" and result.color_hl:find("lsp_documentColor_mf_", 1, true) == 1,
		"completion still shows a Tailwind color as a color square",
		("kind=%s highlight=%s"):format(result.color_kind, result.color_hl)
	)
end

local function check_keymap_descriptions(channel)
	-- gitsigns sets its keys only in files that git tracks, so open one from the config repo
	vim.rpcrequest(channel, "nvim_command", "edit " .. CONFIG_DIR .. "/lua/reed/keymaps.lua")
	local attached = vim.wait(LSP_TIMEOUT_MS, function()
		return remote_lua(channel, "return vim.b.gitsigns_status_dict ~= nil")
	end, 250)
	check(attached, "gitsigns attaches to a file tracked by git", "no gitsigns status")

	local missing = remote_lua(
		channel,
		[[
		local config_dir = ...
		local seen, missing = {}, {}
		local function note(where, desc)
			if seen[where] then return end
			seen[where] = true
			if not desc or desc == "" then table.insert(missing, where) end
		end
		-- keymaps set by the config's own files (recorded by RECORD_KEYMAPS)
		for _, call in ipairs(_G.__startup_test_keymaps or {}) do
			if call.source:sub(1, #config_dir + 1) == "@" .. config_dir then
				note(("%s:%d %s"):format(call.source:sub(#config_dir + 3), call.line, tostring(call.lhs)), call.desc)
			end
		end
		-- keys = { ... } entries in the plugin specs, which lazy.nvim maps for us
		for _, mode in ipairs({ "n", "x", "o", "i" }) do
			for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
				local info = map.callback and debug.getinfo(map.callback, "S")
				if info and info.source:find("lazy/core/handler/keys.lua", 1, true) then
					note(("lazy keys (%s) %s"):format(mode, map.lhs), map.desc)
				end
			end
		end
		table.sort(missing)
		return missing
	]],
		{ CONFIG_DIR }
	)
	check(#missing == 0, "every keymap from the config has a description", "\n    " .. table.concat(missing, "\n    "))
end

local function check_messages(channel)
	local messages = vim.rpcrequest(channel, "nvim_exec2", "messages", { output = true }).output
	local bad = {}
	for line in messages:gmatch("[^\n]+") do
		for _, pattern in ipairs(BAD_MESSAGE_PATTERNS) do
			if line:match(pattern) then
				table.insert(bad, line)
				break
			end
		end
	end
	check(#bad == 0, "no warning or error in :messages", "\n    " .. table.concat(bad, "\n    "))
end

local function check_deprecated_health(channel)
	vim.rpcrequest(channel, "nvim_command", "checkhealth vim.deprecated")
	local report = table.concat(buffer_lines(channel), "\n")
	check(
		report:find("No deprecated functions detected", 1, true) ~= nil,
		":checkhealth vim.deprecated is clean",
		"\n" .. report
	)
end

local function run()
	check_config_names()

	local sample_dir = vim.fn.tempname()
	vim.fn.mkdir(sample_dir, "p")
	write_samples(sample_dir)

	local channel = start_editor(sample_dir)
	check_language_servers(channel)
	use_remapped_keys(channel)
	check_no_duplicate_diagnostics(channel)
	check_completion_format(channel)
	check_keymap_descriptions(channel)
	check_messages(channel)
	check_deprecated_health(channel)
	vim.fn.jobstop(channel)
	vim.fn.delete(sample_dir, "rf")

	io.write(("[INFO] %s\n"):format(failures == 0 and "all checks passed" or (failures .. " checks failed")))
	os.exit(failures == 0 and 0 or 1)
end

run()
