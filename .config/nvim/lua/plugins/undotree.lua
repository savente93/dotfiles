return {
  'mbbill/undotree',
  config = function()
    vim.g.undotree_SetFocusWhenToggle = 1

    vim.keymap.set('n', '<leader>u', function()
      vim.cmd [[UndotreeToggle]]
    end)
  end,
}
