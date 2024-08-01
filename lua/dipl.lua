local M = {}

function M.enable()
  print("АААА НЕГР!!!!!!")
end

function M.setup(opts)
  M.DICTIONARY_PATH = opts.DICTIONARY_PATH
  assert(M.DICTIONARY_PATH, "Путь к словарю либо не задан, либо задан неверно")
  --- CONFIG ---
  local KEYMAP_ENABLE_PLUGIN = opts.ENABLE_PLUGIN_KEYMAP or "<C-l>"
  local KEYMAP_DISABLE_PLUGIN = opts.KEYMAP_DISABLE_PLUGIN or "<C-j>"
  local KEYMAP_MENU = opts.KEYMAP_MENU or "<C-k>"
  --- CONFIG END ---

  --- MAPPINGS ---
  vim.keymap.set('n', KEYMAP_ENABLE_PLUGIN, function()
    require("dipl").enable()
  end)
end

return M
