-- Abbreviations
-- =============

-- Python abbreviations
vim.cmd([[
  iabbrev docstr """<CR>A useful description.<CR><CR>Args:<CR><Tab>param1 (type): The first parameter.<CR><Tab>param2 (type): The second parameter.<CR><CR>Returns:<CR><Tab>The return value.<CR>"""<Up><Up><Up><Up><Up><Up><Up><Up><Up><Right><Right><Right>
]])

-- Markdown abbreviations
vim.cmd([[
  iabbrev notesfrontmatter ---<CR>layout: notes<CR>title:<CR>aside:<CR><Tab>toc: true<CR>sidebar:<CR><Tab>nav: notes-nav<CR>---<Up><Up><Up><Up><Up><Right><Right><Right>
]])