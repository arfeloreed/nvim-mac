-- shorten function name
local key = vim.keymap.set
-- remap space as leader key (not in Select mode, where a typed space must replace the selection)
key({ "n", "x", "o" }, "<Space>", "<Nop>", { silent = true, desc = "Leader key (does nothing on its own)" })
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

key("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
-- leader + z opens the file explorer (netrw) in the current file's folder
key("n", "<leader>z", vim.cmd.Ex, { desc = "Open file explorer in this file's folder" })

-- CTRL + s to save
key("n", "<C-s>", [[:w<CR>]], { desc = "Save file" })
-- leader + q closes the window without saving (Neovim quits with the last window)
key("n", "<leader>q", [[:q!<CR>]], { desc = "Quit without saving (closes Neovim if last window)" })

-- for commenting
-- leader + / for comment
key(
	"n",
	"<leader>/",
	"<cmd>lua require('Comment.api').toggle.linewise.current()<CR>",
	{ silent = true, desc = "Toggle comment on this line" }
)
key(
	"x",
	"<leader>/",
	"<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ silent = true, desc = "Toggle comment on the selection" }
)

-- moving lines ("x" is Visual mode only; "v" would also catch J and K typed into a snippet placeholder)
key("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
key("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })
key("n", "<C-d>", "<C-d>zz", { desc = "Half page down, cursor centered" })
key("n", "<C-u>", "<C-u>zz", { desc = "Half page up, cursor centered" })
-- centers the cursor during navigation on search
key("n", "n", "nzzzv", { desc = "Next search result, centered" })
key("n", "N", "Nzzzv", { desc = "Previous search result, centered" })
key("x", "<leader>p", [["_dP]], { desc = "Paste over selection, keep the copied text" })
-- select by syntax node with Neovim 0.12's treesitter selection (the same as the built-in
-- `an` / `in`); in a file without a parser these do nothing
key({ "n", "x" }, "<C-Space>", function()
	vim.treesitter.select("parent", vim.v.count1)
end, { desc = "Select the syntax node at the cursor, or grow the selection" })
key("x", "<BS>", function()
	vim.treesitter.select("child", vim.v.count1)
end, { desc = "Shrink the selection back to the smaller syntax node" })
key(
	"n",
	"<leader>rw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace the word under the cursor in this file" }
)

-- window management
key("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
key("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
key("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
key("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

key("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
key("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
key("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
key("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
key("n", "<leader>tb", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
