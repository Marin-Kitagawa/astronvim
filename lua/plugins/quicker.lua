return {
  "stevearc/quicker.nvim",
  event = "FileType qf",
  ---@module "quicker"
  ---@type quicker.SetupOptions
  opts = {
    -- Local options to set for quickfix
    opts = {
      buflisted     = false,
      number        = false,
      relativenumber = false,
      signcolumn    = "auto",
      winfixheight  = true,
      wrap          = false,
    },
    use_default_opts  = true,
    keys              = {},
    on_qf             = function(_bufnr) end,
    edit = {
      enabled  = true,
      autosave = "unmodified",
    },
    constrain_cursor = true,
    highlight = {
      treesitter   = true,
      lsp          = true,
      load_buffers = false,
    },
    follow = { enabled = false },
    type_icons = {
      E = "󰅚 ",
      W = "󰀪 ",
      I = " ",
      N = " ",
      H = " ",
    },
    borders = {
      vert         = "┃",
      strong_header = "━",
      strong_cross = "╋",
      strong_end   = "┫",
      soft_header  = "╌",
      soft_cross   = "╂",
      soft_end     = "┨",
    },
    trim_leading_whitespace = "common",
    max_filename_width = function()
      return math.floor(math.min(95, vim.o.columns / 2))
    end,
    header_length = function(_type, start_col)
      return vim.o.columns - start_col
    end,
  },
}
