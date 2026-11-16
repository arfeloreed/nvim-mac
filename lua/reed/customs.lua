local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})
local cmdline_group = augroup("CmdlineAutocomplete", {})

-- show suggestions while typing a command (:) or a search (/ ?), without pressing Tab
-- (Neovim 0.12, :help cmdline-autocompletion; 'wildmode' is set in settings.lua)
autocmd("CmdlineChanged", {
	group = cmdline_group,
	pattern = { ":", "/", "?" },
	callback = function()
		vim.fn.wildtrigger()
	end,
})

-- for highlight when yanking
autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})
