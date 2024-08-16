local M = {}
-- dictionary structure - {word = {{key, translate, colour, comment},}
local DICTIONARY = {}

function M.parse_word_fields(raw_dictionary, from_line, to_line)
  local value_table = {}

  -- Structure for dict {word = {key = string, translate = string, colour = string, comment = string},}
  for i = from_line, to_line do
    -- Dict consist a line values for word
    local line_result = {}
    -- Temporary table for store values in a line
    local table_values = {}

    -- Filling line with values
    for value in raw_dictionary[i]:gmatch('([^,{}\t]+)') do
      table.insert(table_values, value)
    end

    -- Placing values in dict
    for x = 1, #M.VALUES_FORMAT do
      line_result[M.VALUES_FORMAT[x]] = table_values[x]
    end

    -- Placing dicts for word in one table
    assert(line_result, "Error while parsing dictionary. Check for syntax errors in dictionary.")
    table.insert(value_table, line_result)
  end

  return value_table
end

-- Parsing raw dictionary table
function M.parse(raw_dictionary)
  local word = nil
  local captured_word_position = nil

  for index = 1, #raw_dictionary do
    local line = raw_dictionary[index]

    if not word and line:match('"(%a+)"') then
      word = line:match('"(%a+)"')
      captured_word_position = index
    elseif string.sub(line, 1, 1) == "]" then
      assert(word, string.format("Dictionary parse error. String: %s", index))
      DICTIONARY[word] = M.parse_word_fields(raw_dictionary, captured_word_position + 1, index - 1)

      word = nil
    end
  end
end

-- Load dictionary in memory
function M.load_dictionary()
  local file, error = io.open(M.DICTIONARY_PATH, "r")
  assert(file, error)

  -- Dictionary without formatting
  local raw_dictionary = {}
  for line in file:lines() do
    table.insert(raw_dictionary, line)
  end

  M.parse(raw_dictionary)
end

-- Highlights keywords from dictionary
function M.highlight_words()
  vim.cmd(":highlight Keyword guibg=" .. M.DEFAULT_COLOUR)

  for word, _ in pairs(DICTIONARY) do
    vim.cmd(":syntax keyword Keyword " .. word)
  end
end

function M.get_comment_popup(comment, winid)
  local Popup = require("nui.popup")

  local popup = Popup({
    relative = {
      type = "win",
      winid = winid,
    },
    size = {
      width = "49%",
      height = 10,
    },

    position = {
      row = "100%",
      col = "100%",
    },
    border = {
      style = "rounded",
      text = {
        top = "Комментарий",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal",
    }
  })

  return popup
end

-- Drawing window with translate variants
function M.draw_menu()
  -- Word under cursos
  local selected_word = vim.fn.expand("<cword>")
  -- Table with dicts for the word
  local values_dicts = DICTIONARY[selected_word]

  -- Winid for create menu and popup in one window
  local shared_winid = vim.api.nvim_get_current_win()
  --- Popup for comment
  local popup = M.get_comment_popup("", shared_winid)

  -- Menu constructor
  local Menu = require("nui.menu")
  -- Menu items for selected word which consists value dicts
  local menu_items = {}
  -- Generate menu.item lines
  local function get_items()
    for i = 1, #values_dicts do
      local str = ""
      for x = 1, #M.VALUES_FORMAT - 1 do
        str = str .. values_dicts[i][M.VALUES_FORMAT[x]]
      end

      -- Inserting index field for drawing position
      values_dicts[i].index = i

      -- Resulting table with items for menu and his values in parts of menu
      table.insert(menu_items, Menu.item(str, values_dicts[i]))
    end
    return menu_items
  end

  local popup_options = {
    relative = "win",

    size = {
      width = "50%",
      height = 10,
    },

    position = {
      row = "100%",
      col = 0,
    },

    border = {
      style = "rounded",
      text = {
        top = selected_word,
        top_align = "center",
      },
    },

    win_options = {
      winhighlight = "Normal:Normal",
    }
  }

  local menu = Menu(popup_options, {
    lines = get_items(),
    keymap = {
      focus_next = { "j", "<Down>" },
      focus_prev = { "k", "<Up>" },
      close = { "<Esc>", "q" },
      submit = { "<CR>" },
    },

    on_close = function()
      if popup then
        popup:unmount()
      end
    end,

    on_change = function(item)
      vim.api.nvim_buf_set_lines(popup.bufnr, 0, 2, false,
        { string.format("%s/%s", item.index, #values_dicts), item.comment })
      popup:mount()
    end,

    on_submit = function(item)
      popup:unmount()
      print(item.key)
    end,
  })
  menu:mount()
end

function M.enable()
  M.load_dictionary()
  M.highlight_words()
  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_MENU, function()
    require('dipl').draw_menu()
  end)

  vim.keymap.set('n', M.KEYMAP_DISABLE_PLUGIN, function()
    require('dipl').disable()
  end)
  --- MAPPINGS END ---
end

function M.disable()
  --- UNMAPPING ---
  vim.keymap.del('n', M.KEYMAP_DISABLE_PLUGIN)
  vim.keymap.del('n', M.KEYMAP_MENU)
  --- UNMAPPING END ---
  vim.cmd(":syntax off")
end

function M.setup(opts)
  --- CONFIG ---
  M.VALUES_FORMAT = { "key", "translate", "color", "comment", }
  M.DICTIONARY_PATH = opts.DICTIONARY_PATH
  M.DEFAULT_COLOUR = "#330066"
  assert(M.DICTIONARY_PATH, "Путь к словарю либо не задан, либо задан неверно")

  M.KEYMAP_ENABLE_PLUGIN = opts.ENABLE_PLUGIN_KEYMAP or "<C-l>"
  M.KEYMAP_DISABLE_PLUGIN = opts.KEYMAP_DISABLE_PLUGIN or "<C-j>"
  M.KEYMAP_MENU = opts.KEYMAP_MENU or "<C-k>"
  --- CONFIG END ---

  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_ENABLE_PLUGIN, function()
    require("dipl").enable()
  end)
  --- MAPPINGS END ---
end

return M
