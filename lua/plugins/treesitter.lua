return {
	"nvim-treesitter/nvim-treesitter",
	-- master is the branch for Neovim 0.11; main is a rewrite that needs Neovim 0.12
	branch = "master",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			ensure_installed = {
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
			},
			sync_install = false,
			auto_install = true,
			-- enable syntax highlighting
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			-- enable indentation
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>", -- bs = backspace
				},
			},
		})
	end,
}
