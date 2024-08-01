-- включаем нумерацию строк
vim.opt.number = true
-- включаем относительную нумерацию строк
-- vim.opt.relativenumber = true
-- не генерить swapfile
vim.opt.swapfile = false
-- цвет темы
vim.opt.background = 'dark'
--
vim.opt.fileencoding = 'utf-8'
vim.opt.winblend = 0 --прозрачность окна
--

-- config.lua
vim.opt.tabstop = 4
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.wrap = true -- отображение строки как одной длинной строки 'true'
--------------------------------------------------------------------------------
--------------------установка менеджера плагинов MINI.DEPS----------------------
-------------------------Plugin manager -"mini.deps"----------------------------
---- https://github.com/echasnovski/mini.deps/blob/main/lua/mini/deps.lua ------
-- Path:   /home/vadim/.var/app/io.neovim.nvim/data/nvim/site/pack/deps/start/mini.nvim
-- Source: https://github.com/echasnovski/mini.nvim
-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
--
-- :DepsUpdate -
-------------------------------------------------------------------------------
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

--------------------------------------------------------------------------------
-----ADD PLUGINS: START---------------------------------------------------------------
local add = MiniDeps.add
---> Neo-tree.nvim -- файловый менеджер --
---> https://github.com/nvim-neo-tree/neo-tree.nvim
---> After installing, run --> :Neotree
add({
  source = "nvim-neo-tree/neo-tree.nvim",
  checkout = "v3.x",
  depends = { "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "s1n7ax/nvim-window-picker" }
})

---> nvim-treesitter -- подсветка синтаксиса
---> https://github.com/nvim-treesitter/nvim-treesitter
-----> https://neovimcraft.com/plugin/nvim-treesitter/nvim-treesitter/index.html
add({
  source = 'nvim-treesitter/nvim-treesitter',
  -- Используйте 'master' при мониторинге обновлений в 'main'
  checkout = 'master',
  monitor = 'main',
  -- Выполняйте действие после каждого оформления заказа
  hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
})
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'lua', 'vimdoc' },
  highlight = { enable = true },
})

---> windwp/nvim-autopairs -- автоматическое закрывание парных скобок
---> https://github.com/windwp/nvim-autopairs

---> bufferline.nvim -- комфортная работа с буферами
---> https://github.com/akinsho/bufferline.nvim
add({
  source = "akinsho/bufferline.nvim",
  version = "*",
  depends = { 'nvim-tree/nvim-web-devicons' }
})
vim.opt.termguicolors = true
require("bufferline").setup {}

---> lualine.nvim -- конфигурация статусной строки
---> https://github.com/nvim-lualine/lualine.nvim
add({
  source = 'nvim-lualine/lualine.nvim',
  depends = { 'nvim-tree/nvim-web-devicons' }
})

-- configuration---
-- Bubbles config for lualine
-- Author: lokesh-krishna
-- MIT license, see LICENSE for more details.

-- stylua: ignore
local colors = {
  blue   = '#80a0ff',
  cyan   = '#79dac8',
  black  = '#080808',
  white  = '#c6c6c6',
  red    = '#ff5189',
  violet = '#d183e8',
  grey   = '#303030',
}

local bubbles_theme = {
  normal = {
    a = { fg = colors.black, bg = colors.violet },
    b = { fg = colors.white, bg = colors.grey },
    c = { fg = colors.white },
  },

  insert = { a = { fg = colors.black, bg = colors.blue } },
  visual = { a = { fg = colors.black, bg = colors.cyan } },
  replace = { a = { fg = colors.black, bg = colors.red } },

  inactive = {
    a = { fg = colors.white, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white },
  },
}

require('lualine').setup {
  options = {
    theme = bubbles_theme,
    component_separators = '',
    section_separators = { left = '', right = '' },
  },
  sections = {
    lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
    lualine_b = { 'filename', 'branch' },
    lualine_c = { '%=', --[[ add your center compoentnts here in place of this comment ]] },
    lualine_x = {},
    lualine_y = { 'encoding', 'filetype', 'progress' },
    lualine_z = { { 'location', separator = { right = '' }, left_padding = 2 }, },
  },
  inactive_sections = {
    lualine_a = { 'filename' },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { 'location' },
  },
  tabline = {},
  extensions = {},
}

-- добавляем плагин с функциями "lua"  - PLENARY.NVIM
add({ source = "nvim-lua/plenary.nvim" })

-- добабляем плагин edluffy/specs.nvim - показывает куда перемещается КУРСОР
add({ source = "edluffy/specs.nvim" })

-------------ADD PLUGINS: FINISH-------------------------------------------------

-----MAPPINGS:-------------------------------------------------------------------
vim.g.mapleader = " " -- клавиша "пробел"

-- NeoTree: START
vim.keymap.set('n', '<leader>e', ':Neotree float focus<CR>')
--- a - append file or dir
--- d - delete
vim.keymap.set('n', '<leader>o', ':Neotree float git_status<CR>')
-- NeoTree: FINISH

require('dipl').setup {
  DICTIONARY_PATH = "path/to/dictionary",
}
