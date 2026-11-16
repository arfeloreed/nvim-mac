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
--   * treesitter highlights and indents each sample (a code block in markdown too),
--     Control+Space / Backspace grow and shrink a selection, and the plugins that read the
--     tree work: JSX comments with {/* */}, and a typed HTML tag gets its closing tag
--   * typing a command (:) or a search (/) shows suggestions without Tab, and Up still
--     recalls command history
--   * a Python problem is reported once, not by two tools
--   * completion shortens long suggestions and still shows Tailwind colors
--   * every keymap the config defines has a description (which-key shows it)
--   * Space gs lists a git repo's modified and untracked files
--   * the colorscheme setup leaves no global function and keeps the background transparent
--   * the markdown preview server starts and answers (a test function replaces the browser)
--   * no warning or error shows up in :messages, and :checkhealth vim.deprecated is clean

local STEP_PAUSE_MS = 150
local STARTUP_TIMEOUT_MS = 10000
local LSP_TIMEOUT_MS = 20000
local PREVIEW_TIMEOUT_MS = 20000
local PICKER_TIMEOUT_MS = 5000
local PARSER_TIMEOUT_MS = 5000
local MENU_TIMEOUT_MS = 2000
local CONFIG_DIR = vim.fn.getcwd()

local SAMPLES = {
	{ file = "sample.lua", text = { "local x = 1", "print(x)" }, servers = { "lua_ls" } },
	{ file = "sample.ts", text = { "const x: number = 1;", "console.log(x);" }, servers = { "ts_ls" } },
	-- the unused import gives the Python check something to report
	{ file = "sample.py", text = { "import os", "", "x = 1", "print(x)" }, servers = { "ruff" } },
	{ file = "sample.html", text = { "<div>hi</div>" }, servers = { "html" } },
	{ file = "sample.css", text = { ".a { color: red; }" }, servers = { "cssls" } },
}

local MARKDOWN_SAMPLE = { file = "sample.md", text = { "# Preview test", "", "Hello." } }

-- A Lua code block inside markdown: on Neovim 0.12 the old nvim-treesitter master branch
-- threw an error here and the file lost its highlighting.
local FENCED_MARKDOWN_SAMPLE = { file = "fenced.md", text = { "# Code", "", "```lua", "local x = 1", "```" } }

local TSX_SAMPLE = {
	file = "sample.tsx",
	text = { "const A = () => (", "  <div>", "    <p>hi</p>", "  </div>", ");" },
}

-- Files that must get treesitter highlighting; indent = true where nvim-treesitter indents.
local TREESITTER_SAMPLES = {
	{ file = "sample.lua", indent = true },
	{ file = "sample.py", indent = true },
	{ file = "sample.ts", indent = true },
	{ file = "sample.html", indent = false },
	{ file = FENCED_MARKDOWN_SAMPLE.file, indent = false },
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
	vim.fn.writefile(MARKDOWN_SAMPLE.text, dir .. "/" .. MARKDOWN_SAMPLE.file)
	vim.fn.writefile(FENCED_MARKDOWN_SAMPLE.text, dir .. "/" .. FENCED_MARKDOWN_SAMPLE.file)
	vim.fn.writefile(TSX_SAMPLE.text, dir .. "/" .. TSX_SAMPLE.file)
end

-- A small git repo holding one modified file and one untracked file.
local function make_git_sample(dir)
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ "first" }, dir .. "/tracked.txt")
	local git = {
		"git",
		"-C",
		dir,
		"-c",
		"user.name=startup-test",
		"-c",
		"user.email=startup-test@example.invalid",
		"-c",
		"commit.gpgsign=false",
	}
	for _, step in ipairs({
		{ "init", "-q" },
		{ "add", "tracked.txt" },
		{ "commit", "-q", "--no-verify", "-m", "sample" },
	}) do
		local result = vim.system(vim.list_extend(vim.deepcopy(git), step)):wait()
		assert(result.code == 0, ("git %s failed in %s: %s"):format(step[1], dir, result.stderr or ""))
	end
	vim.fn.writefile({ "changed" }, dir .. "/tracked.txt")
	vim.fn.writefile({ "new" }, dir .. "/untracked.txt")
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

local function diagnostic_float_shown(channel)
	return remote_lua(
		channel,
		[[
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
				if table.concat(lines, "\n"):find("test diagnostic", 1, true) then
					return true
				end
			end
		end
		return false
	]]
	)
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
	check(diagnostic_float_shown(channel), "]d shows the diagnostic in a floating window", "no float with the message")
	press(channel, "<Esc>")
	-- close the float from ]d so the next check sees only the one [d opens
	remote_lua(
		channel,
		[[
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				vim.api.nvim_win_close(win, true)
			end
		end
	]]
	)
	press(channel, "[d")
	check(diagnostic_float_shown(channel), "[d shows the diagnostic in a floating window", "no float with the message")
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

local function treesitter_state(channel)
	return remote_lua(
		channel,
		[[
		local buf = vim.api.nvim_get_current_buf()
		local injected = {}
		local ok, err = pcall(function()
			local parser = vim.treesitter.get_parser(buf)
			parser:parse(true)
			for lang in pairs(parser:children()) do
				table.insert(injected, lang)
			end
		end)
		return {
			highlighted = vim.treesitter.highlighter.active[buf] ~= nil,
			parse_error = ok and "" or tostring(err),
			injected = injected,
			indentexpr = vim.bo[buf].indentexpr,
		}
	]]
	)
end

local function selected_text(channel)
	return remote_lua(
		channel,
		[[
		local mode = vim.fn.mode()
		if not mode:match("^[vV\22]") then
			return ""
		end
		return table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode }), "\n")
	]]
	)
end

local function check_treesitter(channel)
	for _, sample in ipairs(TREESITTER_SAMPLES) do
		-- the Visual J/K check left sample.lua modified, and :edit of the current file refuses
		remote_lua(channel, "if vim.fn.expand('%:t') ~= ... then vim.cmd.edit(...) end", { sample.file })
		local state = treesitter_state(channel)
		vim.wait(PARSER_TIMEOUT_MS, function()
			state = treesitter_state(channel)
			return state.highlighted
		end, 100)
		check(
			state.highlighted and state.parse_error == "",
			("treesitter highlights %s"):format(sample.file),
			("highlighted=%s parse error=%s"):format(tostring(state.highlighted), state.parse_error)
		)
		if sample.indent then
			check(
				state.indentexpr:find("nvim.treesitter") ~= nil,
				("treesitter indents %s"):format(sample.file),
				("indentexpr=%q"):format(state.indentexpr)
			)
		end
		if sample.file == FENCED_MARKDOWN_SAMPLE.file then
			check(
				vim.list_contains(state.injected, "lua"),
				"the Lua code block in markdown gets the Lua parser",
				("injected languages: %s"):format(table.concat(state.injected, ", "))
			)
		end
	end

	-- Control+Space starts a selection on the syntax node at the cursor and grows it;
	-- Backspace shrinks it back
	vim.rpcrequest(channel, "nvim_command", "buffer sample.lua")
	remote_lua(channel, "vim.api.nvim_win_set_cursor(0, { 2, 6 })") -- the x in print(x)
	press(channel, "<C-Space>")
	local first = selected_text(channel)
	press(channel, "<C-Space>")
	local grown = selected_text(channel)
	press(channel, "<BS>")
	local shrunk = selected_text(channel)
	press(channel, "<Esc>")
	check(
		first:find("x", 1, true) ~= nil,
		"Control+Space selects the node at the cursor",
		("selected=%q"):format(first)
	)
	check(
		#grown > #first and grown:find(first, 1, true) ~= nil,
		"Control+Space again grows the selection",
		("first=%q then=%q"):format(first, grown)
	)
	check(shrunk == first, "Backspace shrinks the selection back", ("first=%q after=%q"):format(first, shrunk))

	-- plugins that read the treesitter tree: nvim-ts-autotag and nvim-ts-context-commentstring
	vim.rpcrequest(channel, "nvim_command", "edit " .. TSX_SAMPLE.file)
	vim.wait(PARSER_TIMEOUT_MS, function()
		return treesitter_state(channel).highlighted
	end, 100)
	remote_lua(channel, "vim.api.nvim_win_set_cursor(0, { 3, 4 })") -- the <p> line
	press(channel, " /")
	local commented = buffer_lines(channel)[3]
	check(
		commented == "    {/* <p>hi</p> */}",
		"Space / comments a JSX line with {/* */}",
		("line=%q"):format(commented)
	)
	press(channel, "u")
	press(channel, "Go<lt>p>") -- <lt> is a typed "<"; nvim_input reads "<p>" as a key name
	press(channel, "<Esc>")
	local typed = buffer_lines(channel)
	check(typed[#typed] == "<p></p>", "typing <p> adds the closing </p>", ("line=%q"):format(typed[#typed]))
	press(channel, "u")
end

local function completion_menu_shown(channel)
	return remote_lua(channel, "return vim.fn.pumvisible() == 1 or vim.fn.wildmenumode() == 1")
end

local function wait_for_completion_menu(channel)
	local shown = false
	vim.wait(MENU_TIMEOUT_MS, function()
		shown = completion_menu_shown(channel)
		return shown
	end, 100)
	return shown
end

local function command_line(channel)
	return remote_lua(channel, "return vim.fn.getcmdline()")
end

local function check_cmdline_autocomplete(channel)
	vim.rpcrequest(channel, "nvim_command", "buffer sample.lua")
	press(channel, "<Esc>")
	-- a command in the history for the Up check below
	press(channel, ':echo "history check"<CR>')

	press(channel, ":Tele")
	local shown = wait_for_completion_menu(channel)
	local typed = command_line(channel)
	check(shown, "typing :Tele shows suggestions without pressing Tab", "no completion menu")
	check(typed == "Tele", "the suggestions leave the typed command alone", ("command line=%q"):format(typed))

	-- Up recalls the history entry that starts with the typed text, even with the menu open
	-- (Neovim 0.12.6 does this itself; the <Up> remap in :help cmdline-autocompletion is not needed)
	press(channel, "<C-u>ec")
	wait_for_completion_menu(channel)
	press(channel, "<Up>")
	local recalled = command_line(channel)
	check(
		recalled == 'echo "history check"',
		"Up still recalls command history while suggestions show",
		("command line=%q"):format(recalled)
	)
	press(channel, "<Esc>")

	press(channel, "/pri")
	shown = wait_for_completion_menu(channel)
	press(channel, "<Esc>")
	check(shown, "typing a search shows suggestions from the file", "no completion menu")
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

local function check_git_status_key(channel, repo_dir, home_dir)
	vim.rpcrequest(channel, "nvim_command", "cd " .. vim.fn.fnameescape(repo_dir))
	press(channel, "<Space>gs")
	local shown = {}
	vim.wait(PICKER_TIMEOUT_MS, function()
		shown = remote_lua(
			channel,
			[[
			if vim.bo.filetype ~= "TelescopePrompt" then return { files = {} } end
			local picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
			if not picker or not picker.manager then return { files = {} } end
			local files = {}
			for entry in picker.manager:iter() do
				files[entry.value] = entry.status
			end
			return { title = picker.prompt_title, files = files }
		]]
		)
		return shown.files["tracked.txt"] ~= nil and shown.files["untracked.txt"] ~= nil
	end, 250)
	press(channel, "<C-c>")
	vim.rpcrequest(channel, "nvim_command", "cd " .. vim.fn.fnameescape(home_dir))

	local files = shown.files or {}
	local detail = ("title=%s tracked.txt=%q untracked.txt=%q"):format(
		tostring(shown.title),
		tostring(files["tracked.txt"]),
		tostring(files["untracked.txt"])
	)
	check(shown.title == "Git Status", "Space gs opens the git status list", detail)
	check(files["tracked.txt"] == " M", "the git status list shows a modified file", detail)
	check(files["untracked.txt"] == "??", "the git status list shows an untracked file", detail)
end

local function check_colors_and_logs(channel)
	local state = remote_lua(
		channel,
		[[
		return {
			global_transparent = _G.Transparent ~= nil,
			normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg,
			colors_name = vim.g.colors_name or "",
			conform_log_level = require("conform.log").level,
		}
	]]
	)
	check(not state.global_transparent, "color-scheme.lua leaves no global Transparent function", "_G.Transparent exists")
	check(state.normal_bg == nil, "the background stays transparent", ("Normal bg=%s"):format(tostring(state.normal_bg)))
	check(
		state.colors_name:find("rose-pine", 1, true) == 1,
		"the rose-pine colorscheme is active",
		("colors_name=%s"):format(state.colors_name)
	)
	check(
		state.conform_log_level >= vim.log.levels.WARN,
		"conform does not write a debug log",
		("conform log level=%d"):format(state.conform_log_level)
	)
end

local function check_markdown_preview(channel)
	-- a test function takes the browser's place: it only records the preview URL
	vim.rpcrequest(
		channel,
		"nvim_exec2",
		table.concat({
			"function! StartupTestBrowser(url)",
			"  let g:startup_test_preview_url = a:url",
			"endfunction",
			"let g:mkdp_browserfunc = 'StartupTestBrowser'",
		}, "\n"),
		{}
	)
	vim.rpcrequest(channel, "nvim_command", "edit " .. MARKDOWN_SAMPLE.file)
	vim.rpcrequest(channel, "nvim_command", "MarkdownPreview")
	local url = ""
	vim.wait(PREVIEW_TIMEOUT_MS, function()
		url = remote_lua(channel, "return vim.g.startup_test_preview_url or ''")
		return url ~= ""
	end, 250)
	local status = ""
	if url ~= "" then
		local result = vim.system({ "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "5", url }):wait()
		status = vim.trim(result.stdout or "")
	end
	pcall(vim.rpcrequest, channel, "nvim_command", "MarkdownPreviewStop")
	check(status == "200", "markdown preview server starts and answers", ("url=%q http=%q"):format(url, status))
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
	local git_dir = vim.fn.tempname()
	make_git_sample(git_dir)

	local channel = start_editor(sample_dir)
	check_language_servers(channel)
	use_remapped_keys(channel)
	check_treesitter(channel)
	check_cmdline_autocomplete(channel)
	check_no_duplicate_diagnostics(channel)
	check_completion_format(channel)
	check_keymap_descriptions(channel)
	check_git_status_key(channel, git_dir, sample_dir)
	check_colors_and_logs(channel)
	check_markdown_preview(channel)
	check_messages(channel)
	check_deprecated_health(channel)
	vim.fn.jobstop(channel)
	vim.fn.delete(sample_dir, "rf")
	vim.fn.delete(git_dir, "rf")

	io.write(("[INFO] %s\n"):format(failures == 0 and "all checks passed" or (failures .. " checks failed")))
	os.exit(failures == 0 and 0 or 1)
end

run()
