-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    close_if_last_window = false,
    enable_git_status = true,
    enable_diagnostics = true,
    filesystem = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true,
      },
      group_empty_dirs = false,
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
    buffers = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true,
      },
    },
    git_status = {
      follow_current_file = {
        enabled = true,
      },
    },
  },
}
