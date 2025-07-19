vim.g.have_nerd_font = true

-- Make relative line numbers default
vim.o.number = true
vim.o.relativenumber = true

vim.opt.shiftwidth = 4
vim.opt.wrap = true
vim.opt.linebreak = true
vim.o.breakindent = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.undofile = true
vim.o.undodir = os.getenv 'HOME' .. '/.vim_undo'

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '┆ ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'
vim.opt.incsearch = true
vim.opt.colorcolumn = '120'

vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
vim.o.confirm = true

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- only one statusline pls
vim.cmd [[highlight WinSeperator guibg=None]]
vim.cmd [[set laststatus=3]]

vim.o.sessionoptions = 'buffers,curdir,folds,globals,tabpages,winpos,winsize'
