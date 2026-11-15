return {
	"roobert/tailwindcss-colorizer-cmp.nvim",
	event = { "InsertEnter" },
	-- its formatter is wired into nvim-cmp's formatting in nvim-cmp.lua
	config = function()
		require("tailwindcss-colorizer-cmp").setup({
			color_square_width = 2,
		})
	end,
}
