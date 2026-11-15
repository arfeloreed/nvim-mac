-- rose-pine with a transparent background
local function use_transparent(colorscheme)
	vim.cmd.colorscheme(colorscheme)
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	config = function()
		use_transparent("rose-pine-main")
	end,
}
