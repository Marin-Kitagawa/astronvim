return {
  {
    -- Local plugin — lives in ~/Projects/asciidoc-render.nvim
    dir  = vim.fs.joinpath(vim.env.USERPROFILE or vim.env.HOME, "Projects", "asciidoc-render.nvim"),
    name = "asciidoc-render.nvim",

    -- Only load for AsciiDoc files
    ft   = { "asciidoc" },

    -- No external dependencies required (asciidoctor must be in PATH for preview)
    dependencies = {},

    opts = {
      -- In-buffer rendering on by default
      enabled = true,

      -- Render update debounce (ms)
      debounce = 60,

      headings = {
        icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
        underline = { [1] = true, [2] = true, [3] = false, [4] = false, [5] = false, [6] = false },
        underline_char = "─",
        conceal = true,
      },

      admonitions = {
        NOTE      = { icon = " ",  label = "NOTE",      hl = "AdocNote"      },
        TIP       = { icon = " ",  label = "TIP",       hl = "AdocTip"       },
        WARNING   = { icon = " ",  label = "WARNING",   hl = "AdocWarning"   },
        CAUTION   = { icon = " ",  label = "CAUTION",   hl = "AdocCaution"   },
        IMPORTANT = { icon = "󰅚 ", label = "IMPORTANT", hl = "AdocImportant" },
      },

      code = {
        border = {
          tl = "╭", t = "─", tr = "╮",
          l  = "│",            r  = "│",
          bl = "╰", b = "─", br = "╯",
        },
        show_lang_badge = true,
      },

      lists = {
        unordered = { "●", "◆", "▸", "›", "·" },
        ordered   = { "➀", "➁", "➂", "➃", "➄", "➅", "➆", "➇", "➈", "➉" },
      },

      hr = { char = "─", center = "✦" },

      quote  = { border = "▌", icon = "❝" },
      images = { icon = "󰥶 " },
      links  = { url_icon = " ", xref_icon = " " },

      attributes = { conceal = false, icon = " " },

      preview = {
        mode         = "browser",
        auto_refresh = true,
        custom_css   = nil,
        output_dir   = nil,
        browser_cmd  = nil,
      },

      keymaps = {
        toggle       = "<leader>at",
        preview      = "<leader>ap",
        next_heading = "]h",
        prev_heading = "[h",
      },
    },

    config = function(_, opts)
      require("asciidoc-render").setup(opts)
    end,
  },
}
