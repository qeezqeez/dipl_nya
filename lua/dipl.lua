local M = {}

-- dictionary structure - {word = [,{key, translate, colour, comment}]
local DICTIONARY = {}

function M.parse_value(line, expected_len)
  local arr_val = {}

  local index = 0
  for word in string.gmatch(line, '([^,\t]+)') do -- [^set] - first caret for excluding all characters in set
    index = index + 1
    if index > expected_len then
      return nil, "Broken format"
    end

    table.insert(arr_val, word:match '^%s*(.*)') -- any set of characters between spaces inserts in arr_val
  end

  return arr_val, nil
end

function M.parse_list(lines, index_start, index_end, list_valname)
  local list_value = {}
  for i = 1, #list_valname do
    list_value[list_valname[i]] = {} -- array
  end

  for i = index_start, index_end do
    local value, msg = M.parse_value(lines[i], #list_valname) -- {}
    assert(value, string.format("%s [String number: %d]\nString = %s", msg, i, lines[i]))

    for x = 1, #list_valname do
      table.insert(list_value[list_valname[x]], value[x])
    end
  end
  return list_value
end

function M.parse_dictionary(lines, format_value)
  local list_valname = {}
  -- insert in table all key words in dictionary structure splitted by , and space
  -- keys (key, translate, color, comment)
  for valname in format_value:gmatch('([^, ]+)') do
    table.insert(list_valname, valname)
  end

  local word = nil
  local start_values = nil
  for i = 1, #lines do
    if word == nil and string.sub(lines[i], 1, 1) == '"' then
      word = string.match(lines[i], '%a+')
      assert(word, string.format("Could not recognize word. String: %d", i))
      start_values = i + 1
    elseif start_values ~= nil and string.sub(lines[i], 1, 1) == ']' then
      DICTIONARY[word] = M.parse_list(lines, start_values, i - 1, list_valname)
      start_values = nil
      word = nil
    end
  end
end

function M.collect_line(abspath_file)
  local file, msg = io.open(abspath_file, "r")
  assert(file, string.format("%s%s", "Could not open file", msg)) -- just return pretty error

  -- insert lines of file in table
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  return lines
end

local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local popup_options = {
  relative = "cursor",
  position = {
    row = 1,
    col = 0,
  },
  border = {
    style = "rounded",
    text = {
      top = "[Choose item]",
      top_align = "center"
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  }
}

local menu = Menu(popup_options, {
  lines = {
    Menu.separator("Group One"),
    Menu.item("Item 1"),
    Menu.item("Item 2"),
    Menu.separator("Group Two", {
      char = "-",
      text_align = "right",
    }),
    Menu.item("Item 3"),
    Menu.item("Item 4"),
  },
  max_width = 20,
  keymap = {
    focus_next = { "j", "<Down>", "<Tab>" },
    focus_prev = { "k", "<Up>", "<S-Tab>" },
    close = { "<Esc>", "<C-c>", "q" },
    submit = { "<CR>", "<Space>" }
  },
  on_close = function()
    print("CLOSED")
  end,
  on_submit = function(item)
    print("SUBMITTED", vim.inspect(item.text))
  end
})

function M.enable()
  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_MENU, function()
    require('dipl').menu()
  end)
  --- MAPPINGS END ---
  M.load_dictionary()
end

function M.disable()
  --- UNMAPPING ---
  print(M.KEYMAP_MENU)
  vim.keymap.del('n', M.KEYMAP_DISABLE_PLUGIN)
  vim.keymap.del('n', M.KEYMAP_MENU)
  --- UNMAPPING END ---
end

function M.menu()
  print('And you does not seemed to understand...')
  menu:mount()
end

function M.setup(opts)
  --- CONFIG ---
  M.DICTIONARY_PATH = opts.DICTIONARY_PATH
  assert(M.DICTIONARY_PATH, "Путь к словарю либо не задан, либо задан неверно")

  M.KEYMAP_ENABLE_PLUGIN = opts.ENABLE_PLUGIN_KEYMAP or "<C-l>"
  M.KEYMAP_DISABLE_PLUGIN = opts.KEYMAP_DISABLE_PLUGIN or "<C-j>"
  M.KEYMAP_MENU = opts.KEYMAP_MENU or "<C-k>"
  --- CONFIG END ---

  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_ENABLE_PLUGIN, function()
    require("dipl").enable()
  end)
  vim.keymap.set('n', M.KEYMAP_DISABLE_PLUGIN, function()
    require('dipl').disable()
  end)
  --- MAPPINGS END ---
end

return M
