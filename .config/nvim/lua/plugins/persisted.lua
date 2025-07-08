return {
  'olimorris/persisted.nvim',
  --  event = 'BufReadPre', -- Ensure the plugin loads only when a buffer has been loaded
  opts = {

    autostart = true,
    follow_cwd = true, -- Change the session file to match any change in the cwd?
    use_git_branch = true, -- Include the git branch in the session file name?
    autoload = true, -- Automatically load the session for the cwd on Neovim startup?
  },
}
