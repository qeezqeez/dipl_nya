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
  vim.cmd(":highlight Keyword guifg=" .. M.DEFAULT_COLOUR)

  for word, _ in pairs(DICTIONARY) do
    vim.cmd(":syntax keyword Keyword " .. word)
  end
end

---@param pos table --
---@param word string -- Word for translate
-- Highlights word under cursos while meni is open
function M.highlight_under_cusror(word, pos, buff_id)
  -- TODO: make it work
  local cursor_row = pos[1] -- one-based
  local cursor_col = pos[2] -- zero-based

  local current_string = vim.api.nvim_buf_get_lines(buff_id, cursor_row - 1, cursor_row, false)[1]
  local word_substring = nil
  local word_pos = nil

  if cursor_col < #word then
    word_substring = current_string:sub(0, #word + cursor_col)
    word_pos = word_substring:find(word) - 1
  else
    word_substring = current_string:sub(cursor_col - (#word - 2), cursor_col + #word)
    word_pos = word_substring:find(word) - #word + cursor_col
    print(word_pos)
  end
  vim.api.nvim_set_hl(1, "MyHighlight", { bg = M.COLOUR_FOR_CHOICE })
  vim.api.nvim_buf_add_highlight(buff_id, 1, "MyHighlight", cursor_row - 1, word_pos, word_pos + #word)
  vim.api.nvim_set_hl_ns(1)

  -- I do not know how it works. I need refactor this by start, but no time to this.
end

---@param pos table -- {start_pos, end_pos}
---@param word string -- Word for translate
-- Insert in text word translate
function M.translate_word(word, pos)
  -- TODO: make it work
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
  -- Winid for create menu and popup in one window
  local shared_winid = vim.api.nvim_get_current_win()
  local shared_buffer = vim.api.nvim_get_current_buf()

  -- Word under cursos
  local selected_word = vim.fn.expand("<cword>")
  local cursor_position = vim.api.nvim_win_get_cursor(shared_winid)

  -- Table with dicts for the word
  local values_dicts = DICTIONARY[selected_word]

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
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
    end,

    on_change = function(item)
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
      vim.api.nvim_buf_set_lines(popup.bufnr, 0, 2, false,
        { string.format("%s/%s", item.index, #values_dicts), item.comment })
      M.highlight_under_cusror(selected_word, cursor_position, shared_buffer)
      popup:mount()
    end,

    on_submit = function(item)
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
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
  M.DEFAULT_COLOUR = opts.DEFAULT_COLOUR or "#18fff2"
  M.COLOUR_FOR_CHOICE = opts.COLOUR_FOR_CHOICE or "#aaa0ff"
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
