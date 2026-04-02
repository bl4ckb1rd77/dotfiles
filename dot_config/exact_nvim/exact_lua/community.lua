-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- colortheme
  { import = "astrocommunity.colorscheme.catppuccin" },
  -- ui
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.recipes.heirline-mode-text-statusline" },
  -- language
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
}
