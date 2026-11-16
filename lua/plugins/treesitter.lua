-- nvim-treesitter's main branch only installs parsers and queries. Neovim 0.12 itself
-- highlights (vim.treesitter.start) and selects by syntax node (Control+Space, set in
-- lua/reed/keymaps.lua); this plugin still supplies the indent expression.
local PARSERS = {
	"c",
	"lua",
	"vim",
	"vimdoc",
	"query",
	"markdown",
	"markdown_inline",
	"python",
	"javascript",
	"go",
	"html",
	"css",
	"bash",
	"typescript",
	"tsx",
	"gitignore",
	"json",
	"yaml",
	"toml",
	-- the master branch installed these on first use (auto_install), which main does not
	-- do; another language needs :TSInstall <language> once (jsonc files use the json parser)
	"git_config",
	"sql",
}

return {
	"nvim-treesitter/nvim-treesitter",
	-- main is the rewrite for Neovim 0.12; master supports Neovim 0.11 at most
	branch = "main",
	lazy = false, -- the main branch does not support lazy-loading
	build = ":TSUpdate",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		-- asynchronous, and a no-op for parsers already installed
		require("nvim-treesitter").install(PARSERS)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("TreesitterStart", {}),
			callback = function(ev)
				local lang = vim.treesitter.language.get_lang(ev.match)
				if not lang or not vim.treesitter.language.add(lang) then
					return
				end
				vim.treesitter.start(ev.buf, lang)
				vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
