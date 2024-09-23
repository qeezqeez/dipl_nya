local M = {}
-- dictionary structure - {word = {{key, translate, colour, comment},}}

local ALL_DICTS = {}          -- Contains all dicts
local CURRENT_DICTIONARY = {} -- Dictionary used for translate
local CURRENT_DICTIONARY_NAME = nil
local DICTIONARIES = {}       -- All used dictionaries words

-- Used for creation custom highlight groups. Please do not touch
local COUNT = 2

-- Highlights keywords from dictionary
function M.highlight_words()
  vim.cmd(":highlight Keyword guifg=" .. M.DEFAULT_COLOUR)

  for word, _ in pairs(DICTIONARIES) do
    vim.cmd(":syntax keyword Keyword " .. word:sub(0, -2))
  end
end

-- Highlights the translated word
function M.highlight_translated_words(buff_id)
  local function parse_line(line, line_num)
    local word = nil
    local translate = nil
    local translate_colour = nil

    local index = {} -- [1] - start, [2] - end
    local sub_line = line
    local index_storage = 0

    while sub_line:find("%([%a]+%)%[[^%]]+(%])") do
      -- used for indexing translate position in file
      index[1], index[2] = sub_line:find("%([%a]+%)%[[^%]]+(%])")
      index[1] = index[1] + index_storage
      index[2] = index[2] + index_storage
      word = sub_line:match("%((%a*)%)")
      translate = sub_line:match("%[(.*)")
      translate = translate:gsub("%].*", "")
      local i = 1
      if not CURRENT_DICTIONARY[word .. "_"] then
        vim.api.nvim_set_hl(111, "TranslateHighlightDefault", { fg = M.NON_ACTIVE_TRANSLATE_COLOUR })
        vim.api.nvim_buf_add_highlight(buff_id, 111, "TranslateHighlightDefault", line_num, index[1] - 1,
          index[1] + #word + #translate + 3)
        vim.api.nvim_set_hl_ns(111)
        sub_line = sub_line:sub(index[2] + 1 - index_storage, -1)
        index_storage = index[2]
      else
        while CURRENT_DICTIONARY[word .. "_"][i] ~= nil do
          if CURRENT_DICTIONARY[word .. "_"][i].translate == translate then
            translate_colour = CURRENT_DICTIONARY[word .. "_"][i].colour
            i = 1
            break
          end
          i = i + 1
        end
        if translate_colour ~= nil then
          vim.api.nvim_set_hl(111, "TranslateHighlight" .. COUNT, { fg = translate_colour })
          vim.api.nvim_buf_add_highlight(buff_id, 111, "TranslateHighlight" .. COUNT, line_num, index[1] - 1,
            index[1] + #word + #translate + 3)
          vim.api.nvim_set_hl_ns(111)

          COUNT = COUNT + 1
          sub_line = sub_line:sub(index[2] + 1 - index_storage, -1)
          index_storage = index[2]
          translate_colour = nil
        else
          vim.api.nvim_set_hl(111, "TranslateHighlightDefault", { fg = M.NON_ACTIVE_TRANSLATE_COLOUR })
          vim.api.nvim_buf_add_highlight(buff_id, 111, "TranslateHighlightDefault", line_num, index[1] - 1,
            index[1] + #word + #translate + 3)
          vim.api.nvim_set_hl_ns(111)
          sub_line = sub_line:sub(index[2] + 1 - index_storage, -1)
          index_storage = index[2]
        end
      end
    end
  end

  local lines_amount = vim.api.nvim_buf_line_count(buff_id)
  local line = nil
  vim.api.nvim_buf_clear_namespace(buff_id, 111, 0, -1)
  for index = 0, lines_amount - 1 do
    line = vim.api.nvim_buf_get_lines(buff_id, index, index + 1, false)[1]
    parse_line(line, index)
  end
end

---@param word string -- Word in text
---@param cursor_pos table -- cursor_pos[[1]] = line (one-based), cursor_pos[[2]] = row (zero-based)
---@return table -- {word_start, word_end}
-- Return word position where word_start include character and word_end exclude character
function M.get_word_position(word, cursor_pos, buff_id)
  local cursor_row = cursor_pos[1] -- one-based
  local cursor_col = cursor_pos[2] -- zero-based

  local current_string = vim.api.nvim_buf_get_lines(buff_id, cursor_row - 1, cursor_row, false)[1]
  local word_substring = nil
  local word_pos = nil

  if cursor_col < #word then
    word_substring = current_string:sub(0, #word + cursor_col)
    word_pos = word_substring:find(word) - 1
  else
    word_substring = current_string:sub(cursor_col - (#word - 2), cursor_col + #word)
    word_pos = word_substring:find(word) - #word + cursor_col
  end
  return { word_start = word_pos, word_end = word_pos + #word }
end

---@param cursor_pos table -- cursor_pos[[1]] = line (one-based), cursor_pos[[2]] = row (zero-based)
---@param word string -- Word for translate
-- Highlights word under cursos while menu is open
function M.highlight_under_cusror(word, cursor_pos, buff_id)
  local word_pos = M.get_word_position(word, cursor_pos, buff_id)
  vim.api.nvim_set_hl(1, "MyHighlight", { bg = M.COLOUR_FOR_CHOICE })
  vim.api.nvim_buf_add_highlight(buff_id, 1, "MyHighlight", cursor_pos[1] - 1, word_pos.word_start, word_pos.word_end)
  vim.api.nvim_set_hl_ns(1)

  -- I do not know how it works. I need refactor this by start, but no time to this.
end

---@param translate_item NuiTree.Node -- Consist word and translate for word
---@param word_pos table {word_start, word_end}
-- Insert in text word translate
function M.translate_word(translate_item, word_pos, line, buff_id, word)
  local line_to_translate = vim.api.nvim_buf_get_lines(buff_id, line - 1, line, false)[1]

  local translated_line = nil
  local sub_start = line_to_translate:sub(1, word_pos.word_start)
  local sub_end = line_to_translate:sub(word_pos.word_end + 1, -1)
  if sub_end:sub(1, 2) == ")[" then
    sub_start = sub_start:sub(1, -2)
    sub_end = sub_end:match("%](.*)")
  end
  translated_line = sub_start .. "(" .. word .. ")[" .. translate_item.translate .. "]" .. sub_end

  vim.api.nvim_buf_set_lines(buff_id, line - 1, line, false, { translated_line })
end

function M.delete_translated_word()
  local buff_id = vim.api.nvim_get_current_buf()
  local win_id = vim.api.nvim_get_current_win()
  local cursor_position = vim.api.nvim_win_get_cursor(win_id)
  local line_number = vim.api.nvim_win_get_cursor(win_id)[1]
  local word = vim.fn.expand("<cword>")

  local line = vim.api.nvim_buf_get_lines(buff_id, line_number - 1, line_number, false)[1]

  local sub_start = line:sub(1, cursor_position[2]):match("(.*)%(")
  local sub_end = line:sub(cursor_position[2], -1):match("%](.*)")
  line = sub_start .. word .. sub_end

  vim.api.nvim_buf_set_lines(buff_id, line_number - 1, line_number, false, { line })
  M.highlight_translated_words(buff_id)
end

-- Return completed comment popup for menu
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
  local values_dicts = CURRENT_DICTIONARY[selected_word .. "_"]

  if values_dicts == nil then
    print("Слова <" .. selected_word .. "> нет в активном словаре.")
    return
  end

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
        if M.VALUES_FORMAT[x] == "colour" then
          str = str
        else
          str = str .. " " .. values_dicts[i][M.VALUES_FORMAT[x]]
        end
      end

      -- Inserting index field for drawing position
      values_dicts[i].index = i
      local NuiLine = require("nui.line")
      local line = NuiLine()
      vim.cmd(":highlight " .. "colour" .. i .. " guifg=" .. values_dicts[i].colour)
      line:append(str, "colour" .. i)

      -- Resulting table with items for menu and his values in parts of menu
      table.insert(menu_items, Menu.item(line, values_dicts[i]))
    end
    return menu_items
  end

  local popup_options = {
    relative = "win",

    size = {
      width = "49%",
      height = 10,
    },

    position = {
      row = "100%",
      col = 0,
    },

    border = {
      style = "rounded",
      text = {
        top = "[" .. CURRENT_DICTIONARY_NAME .. "] " .. selected_word,
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
      M.highlight_translated_words(shared_buffer)
    end,

    on_change = function(item, menu)
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
      local comment = {}
      for i in item.comment:gmatch("[^%c]*") do
        if i ~= "" then
          table.insert(comment, i)
        end
      end
      vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false,
        { string.format("%s/%s", item.index, #values_dicts), unpack(comment) })
      M.highlight_under_cusror(selected_word, cursor_position, shared_buffer)
      popup:mount()
    end,

    on_submit = function(item)
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
      popup:unmount()
      M.translate_word(item, M.get_word_position(selected_word, cursor_position, shared_buffer), cursor_position[1],
        shared_buffer, selected_word)
      M.highlight_translated_words(shared_buffer)
    end,
  })
  menu:mount()
end

function M.draw_comment()
  local word = vim.fn.expand("<cword>")

  local winid = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winid)

  local line = vim.api.nvim_get_current_line()
  local translate = line:sub(cursor[2], -1):match("%[([^%]]*)")

  local Popup = require("nui.popup")
  local popup = Popup({
    position = {
      row = "40%",
      col = "40%"
    },
    relative = "editor",
    size = {
      width = M.COMMENT_POPUP_SIZE.col,
      height = M.COMMENT_POPUP_SIZE.row,
    },
    focusable = true,
    border = {
      style = "rounded"
    },
    buf_options = {
      readonly = true,
      modifiable = false,
    },
    enter = true,
  })

  local translate_num = nil
  if CURRENT_DICTIONARY[word .. "_"] == nil then
    print("Данного слова нет в активном словаре.")
    return
  end
  for i = 1, #CURRENT_DICTIONARY[word .. "_"] do
    if CURRENT_DICTIONARY[word .. "_"][i].translate == translate then
      translate_num = i
      break
    end
  end
  if translate_num == nil then
    print("У слова нет перевода, либо задан несуществующий в активном словаре перевод.")
    return
  end

  local comment = {}
  for i in CURRENT_DICTIONARY[word .. "_"][translate_num].comment:gmatch("[^%c]*") do
    if i ~= "" then
      table.insert(comment, i)
    end
  end
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false,
    { string.format("%s/%s", translate_num, #CURRENT_DICTIONARY[word .. "_"]),
      unpack(comment) })

  popup:map("n", { "q", "<esc>" }, function() popup:unmount() end, { noremap = true })
  popup:mount()
end

function M.draw_current_dictionary_selecter()
  local Menu = require("nui.menu")
  local current_buffer = vim.api.nvim_get_current_buf()

  local function get_lines()
    local function get_keyword_num(dict)
      local counter = 0
      for _, _ in pairs(dict) do
        counter = counter + 1
      end
      return counter
    end
    local items = {}
    for _, v in ipairs(ALL_DICTS) do
      local item = Menu.item(v[2] .. " [" .. get_keyword_num(v[1]) .. "]", v)
      table.insert(items, item)
    end
    return items
  end

  local popup_options = {
    relative = "win",

    size = {
      width = M.CURRENT_DICTIONARY_MENU_SIZE.col,
      height = M.CURRENT_DICTIONARY_MENU_SIZE.row,
    },

    position = {
      row = "30%",
      col = "30%",
    },

    border = {
      style = "rounded",
      text = {
        top = "Выбор словаря",
        top_align = "center",
      },
    },

    win_options = {
      winhighlight = "Normal:Normal",
    }
  }

  local menu = Menu(popup_options, {
    lines = get_lines(),
    keymap = {
      focus_next = { "j", "<Down>" },
      focus_prev = { "k", "<Up>" },
      close = { "<Esc>", "q" },
      submit = { "<CR>" },
    },

    on_close = function()
    end,

    on_change = function()
    end,

    on_submit = function(item)
      CURRENT_DICTIONARY = item[1]
      CURRENT_DICTIONARY_NAME = item[2]
      M.highlight_translated_words(current_buffer)
    end,
  })
  menu:mount()
end

function M.enable()
  local current_buffer = vim.api.nvim_get_current_buf()
  ALL_DICTS = require("dipl_dicts")
  package.loaded["dipl_dicts"] = nil

  for _, words in ipairs(ALL_DICTS) do
    for k, v in pairs(words[1]) do
      DICTIONARIES[k] = v
    end
  end

  CURRENT_DICTIONARY = DICTIONARIES

  M.highlight_words()
  M.highlight_translated_words(current_buffer)
  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_MENU, function()
    require('dipl').draw_menu()
  end)

  vim.keymap.set('n', M.KEYMAP_DISABLE_PLUGIN, function()
    require('dipl').disable()
  end)

  vim.keymap.set('n', M.KEYMAP_DELETE_TRANSLATE, function()
    require("dipl").delete_translated_word()
  end)

  vim.keymap.set("n", M.KEYMAP_GET_COMMENT, function()
    require("dipl").draw_comment()
  end)

  vim.keymap.set('n', M.KEYMAP_SELECT_CURRENT_DICTIONARY, function()
    require("dipl").draw_current_dictionary_selecter()
  end)
  --- MAPPINGS END ---
end

function M.disable()
  --- UNMAPPING ---
  vim.keymap.del('n', M.KEYMAP_DISABLE_PLUGIN)
  vim.keymap.del('n', M.KEYMAP_MENU)
  vim.keymap.del('n', M.KEYMAP_DELETE_TRANSLATE)
  vim.keymap.del('n', M.KEYMAP_GET_COMMENT)
  vim.keymap.del('n', M.KEYMAP_SELECT_CURRENT_DICTIONARY)
  --- UNMAPPING END ---
  vim.cmd(":syntax off")
  vim.api.nvim_set_hl_ns(0)
end

function M.setup(opts)
  --- CONFIG ---
  M.VALUES_FORMAT = { "key", "translate", "colour", "comment", }
  M.DEFAULT_COLOUR = opts.DEFAULT_COLOUR or "#18fff2"
  M.NON_ACTIVE_TRANSLATE_COLOUR = opts.NON_ACTIVE_TRANSLATE_COLOUR or "#66aacc"
  M.COLOUR_FOR_CHOICE = opts.COLOUR_FOR_CHOICE or "#aaa0ff"
  M.DICTS = opts.DICTS
  M.COMMENT_POPUP_SIZE = opts.COMMENT_POPUP_SIZE or { row = 10, col = 40 }
  M.CURRENT_DICTIONARY_MENU_SIZE = opts.CURRENT_DICTIONARY_MENU_SIZE or { row = 10, col = 100 }

  M.KEYMAP_ENABLE_PLUGIN = opts.ENABLE_PLUGIN_KEYMAP or "<C-l>"
  M.KEYMAP_DISABLE_PLUGIN = opts.KEYMAP_DISABLE_PLUGIN or "<C-j>"
  M.KEYMAP_MENU = opts.KEYMAP_MENU or "<C-k>"
  M.KEYMAP_DELETE_TRANSLATE = opts.KEYMAP_DELETE_TRANSLATE or "<C-d>"
  M.KEYMAP_GET_COMMENT = opts.KEYMAP_GET_COMMENT or "<C-c>"
  M.KEYMAP_SELECT_CURRENT_DICTIONARY = opts.KEYMAP_SELECT_CURRENT_DICTIONARY or "<C-a>"
  --- CONFIG END ---

  --- MAPPINGS ---
  vim.keymap.set('n', M.KEYMAP_ENABLE_PLUGIN, function()
    require("dipl").enable()
  end)
  --- MAPPINGS END ---
end

return M
