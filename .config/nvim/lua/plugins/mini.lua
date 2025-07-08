return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()
    require('mini.tabline').setup()
    require('mini.splitjoin').setup()
    require('mini.bracketed').setup()
    require('mini.comment').setup()
    require('mini.clue').setup()
    require('mini.pairs').setup()
    require('mini.jump').setup()
    require('mini.jump2d').setup()
    require('mini.completion').setup()
    require('mini.icons').setup()
    require('mini.snippets').setup()
  end,
}
