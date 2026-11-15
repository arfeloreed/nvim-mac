-- Integration test: snippet jump keys (Tab / Shift+Tab) with the real config loaded.
-- Run from the config folder:
--   nvim --headless -l tests/snippet_jump_test.lua
-- Exits 0 when every case passes, 1 otherwise.
--
-- The test drives a second Neovim (started with the real config) through nvim_input,
-- the same input queue a keyboard uses, and pauses between key presses so plugins that
-- react on the next tick (nvim-cmp, LuaSnip) behave as they do for a person typing.

local STEP_PAUSE_MS = 150
local STARTUP_TIMEOUT_MS = 10000

local function start_editor()
	local channel = vim.fn.jobstart({ "nvim", "--embed", "--headless" }, { rpc = true })
	assert(channel > 0, "could not start the embedded Neovim (jobstart returned " .. channel .. ")")
	local ready = vim.wait(STARTUP_TIMEOUT_MS, function()
		local ok = pcall(vim.rpcrequest, channel, "nvim_eval", "1")
		return ok
	end, 100)
	assert(ready, "embedded Neovim did not answer within " .. STARTUP_TIMEOUT_MS .. " ms")
	return channel
end

local function press(channel, keys)
	vim.rpcrequest(channel, "nvim_input", keys)
	vim.wait(STEP_PAUSE_MS)
end

local function current_line(channel)
	return vim.rpcrequest(channel, "nvim_get_current_line")
end

local function fresh_buffer(channel)
	press(channel, "<Esc>")
	vim.rpcrequest(channel, "nvim_command", "enew! | setlocal buftype=nofile")
end

local EXPAND_SNIPPET = "i<Cmd>lua require('luasnip').lsp_expand('foo(${1:aa}, ${2:bb})')<CR>"

local cases = {
	{
		name = "Typing right after expansion fills the first placeholder",
		steps = { EXPAND_SNIPPET, "xx", "<Esc>" },
		expected = "foo(xx, bb)",
	},
	{
		name = "Tab jumps from the first placeholder to the second",
		steps = { EXPAND_SNIPPET, "<Tab>", "zz", "<Esc>" },
		expected = "foo(aa, zz)",
	},
	{
		name = "Shift+Tab jumps back to the first placeholder",
		steps = { EXPAND_SNIPPET, "<Tab>", "zz", "<S-Tab>", "yy", "<Esc>" },
		expected = "foo(yy, zz)",
	},
	-- An active placeholder is in Select mode: the first key typed must replace it,
	-- not run a Visual-mode keymap (J, K and the Space leader exist in Visual mode).
	{
		name = "Typing K first in a placeholder types K",
		steps = { EXPAND_SNIPPET, "K", "y", "<Esc>" },
		expected = "foo(Ky, bb)",
	},
	{
		name = "Typing J first in a placeholder types J",
		steps = { EXPAND_SNIPPET, "J", "y", "<Esc>" },
		expected = "foo(Jy, bb)",
	},
	{
		name = "Typing Space first in a placeholder types a space",
		steps = { EXPAND_SNIPPET, "<Space>", "y", "<Esc>" },
		expected = "foo( y, bb)",
	},
	{
		name = "Tab outside a snippet still inserts indentation",
		steps = { "i", "<Tab>", "x", "<Esc>" },
		expected = "  x",
	},
	{
		-- Without a snippet, Shift+Tab keeps Vim's own behavior (it inserts a tab).
		name = "Shift+Tab outside a snippet keeps its normal behavior",
		steps = { "i", "x", "<S-Tab>", "<Esc>" },
		expected = "x ",
	},
}

local function run()
	local channel = start_editor()

	-- Enter and leave Insert mode once so lazy.nvim loads nvim-cmp and LuaSnip.
	fresh_buffer(channel)
	press(channel, "i")
	press(channel, "<Esc>")

	local failures = 0
	for _, case in ipairs(cases) do
		fresh_buffer(channel)
		for _, step in ipairs(case.steps) do
			press(channel, step)
		end
		local actual = current_line(channel)
		if actual == case.expected then
			io.write(("[PASS] %s\n"):format(case.name))
		else
			failures = failures + 1
			io.write(("[FAIL] %s: expected %q, received %q\n"):format(case.name, case.expected, actual))
		end
	end

	vim.fn.jobstop(channel)
	io.write(("[INFO] %d of %d cases passed\n"):format(#cases - failures, #cases))
	os.exit(failures == 0 and 0 or 1)
end

run()
