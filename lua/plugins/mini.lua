-- mini.nvim was already installed here but no modules were being set up, so it
-- was sitting on disk doing nothing. These three cost no extra download.
--
-- surround  -- add/change/delete quotes, brackets and tags around text
-- ai        -- smarter `a`/`i` text objects (function, argument, block)
-- animate   -- animated window open/close/resize and cursor movement
--
-- Surround is on the `gs` prefix, not the usual `s`, so that flash.nvim can own
-- `s` for jumping. `gsa` = add, `gsd` = delete, `gsr` = replace.

---@type LazySpec
return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    -- mini.nvim bundles its own copy of every mini module, including mini.icons,
    -- which AstroNvim also installs standalone as `nvim-mini/mini.icons`. Both
    -- provide the `mini.icons` module, and this copy can win on the runtimepath.
    -- Whichever copy wins still has to have setup() called, or its highlight
    -- groups (MiniIconsAzure and friends) never get created and heirline errors
    -- out drawing the statusline. setup() sets the MiniIcons global, so guard on
    -- that rather than setting it up twice.
    if not _G.MiniIcons then require("mini.icons").setup() end

    require("mini.surround").setup {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
        suffix_last = "l",
        suffix_next = "n",
      },
    }

    local ai = require "mini.ai"
    ai.setup {
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter { -- `ao` / `io` around a block, loop or conditional
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        },
        f = ai.gen_spec.treesitter { a = "@function.outer", i = "@function.inner" },
        c = ai.gen_spec.treesitter { a = "@class.outer", i = "@class.inner" },
      },
    }

    local animate = require "mini.animate"
    animate.setup {
      -- snacks.scroll already animates scrolling; running both double-animates it
      scroll = { enable = false },
      cursor = { timing = animate.gen_timing.linear { duration = 80, unit = "total" } },
      resize = { timing = animate.gen_timing.linear { duration = 100, unit = "total" } },
      open = { timing = animate.gen_timing.linear { duration = 120, unit = "total" } },
      close = { timing = animate.gen_timing.linear { duration = 120, unit = "total" } },
    }
  end,
}
