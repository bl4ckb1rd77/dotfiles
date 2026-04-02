return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
      enable_git_status = true,
      buffers = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
      },
      window = {
        position = "left",
        width = 50,
      },
      sources = {
        "filesystem",
        "document_symbols",
      },
      source_selector = {
        winbar = true,
        statusbar = false,
        sources = {
          { source = "filesystem" },
          { source = "document_symbols" },
        },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            ".DS_Store",
          },
          never_show = {},
        },
      },
    },
  },
}
