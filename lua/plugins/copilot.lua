-- copilot.vim accepts its suggestions with <Tab> by default, which collides
-- with blink.cmp's <Tab> (menu navigation / snippet jumping). blink.cmp owns
-- <Tab>; Copilot suggestions are accepted with <M-CR> (Alt+Enter) instead.
-- copilot.vim's other defaults (<M-]> next, <M-[> previous) are untouched.
return {
  'github/copilot.vim',
  init = function()
    vim.g.copilot_no_tab_map = true
  end,
  config = function()
    vim.keymap.set('i', '<M-CR>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      silent = true,
      desc = 'Accept Copilot suggestion',
    })
  end,
}
