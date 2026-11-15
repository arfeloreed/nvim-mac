return {
	"christoomey/vim-tmux-navigator", -- tmux & split window navigation
	cmd = {
		"TmuxNavigateLeft",
		"TmuxNavigateDown",
		"TmuxNavigateUp",
		"TmuxNavigateRight",
		"TmuxNavigatePrevious",
	},
	keys = {
		{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Go to the window on the left" },
		{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Go to the window below" },
		{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Go to the window above" },
		{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Go to the window on the right" },
		{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Go back to the previous window" },
	},
}
