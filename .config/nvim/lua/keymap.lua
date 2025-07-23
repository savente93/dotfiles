-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- NOTE: file keymaps
vim.keymap.set('n', '<leader>fw', ':wa<CR>', { desc = 'Write all open files' })
vim.keymap.set('n', '<leader>fc', ':bd<CR>', { desc = 'Close current file' })

-- NOTE: undo keymaps
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle [U]ndoTree' })
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })
vim.keymap.set('n', '<C-r>', '<Nop>')

-- NOTE: Visual mode
--
-- move selected visual lines up and down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selected lines up' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selected lines down' })

-- NOTE: Movement

-- keep cursor in same place on screen while moving around
vim.keymap.set('n', 'K', 'mzK`z', { desc = 'Join line up' })
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join line down' })

vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '=ap', "ma=ap'a", { desc = 'format paragraph' })

-- NOTE: Pasting

-- paste without losing current register
vim.keymap.set('x', 'P', [["_dP]], { desc = 'Paste without yanking' })
vim.keymap.set('x', 'p', [["_dp]], { desc = 'Paste without yanking' })
vim.keymap.set({ 'n', 'v' }, '<A-d>', '"_d', { desc = 'Delete without yanking' })

-- NOTE: Yanking
--
-- yank into syste clipboard
vim.keymap.set('n', '<leader>Y', [[ggVG"+Y<C-o>]], { desc = 'Yank entire file into system clipboard' })
vim.keymap.set('v', 'Y', '"+y', { desc = 'yank into system clipboard' })

vim.keymap.set('n', '<leader>fr', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace occurences under cursor' })

vim.keymap.set('n', ']t', function()
  require('todo-comments').jump_next()
end, { desc = 'Next todo comment' })

vim.keymap.set('n', '[t', function()
  require('todo-comments').jump_prev()
end, { desc = 'Previous todo comment' })

vim.keymap.set('n', '<leader>qt', function()
  vim.cmd [[ TodoTelescope ]]
end, { desc = 'Previous todo comment' })
