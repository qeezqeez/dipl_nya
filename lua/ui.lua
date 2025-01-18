local M = {}

-- Return completed comment popup for menu.
function M.get_comment_popup(winid)
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

---@param dictionary table -- Current selected dictionary.
---@param dictionary_name string -- Name for dictionary.
---@param buff_id integer -- Buffer id.
---@param win_id integer -- Window id.
---@param word string -- Word(s) for work.
---@param word_pos table -- {start - zero-based, end - zero-based, line - one-based}
-- Draw window with translate variants.
function M.draw_menu(dictionary, dictionary_name, buff_id, win_id, word, word_pos)
  -- Check current dictionary. If choosed no one - return none.
  if CURRENT_DICTIONARY_NAME == nil then
    print("Вы не выбрали активный словарь.")
    return
  end

  -- Winid for create menu and popup in one window.
  local shared_winid = vim.api.nvim_get_current_win()
  local shared_buffer = vim.api.nvim_get_current_buf()

  -- Word under cursos.
  local cursor_position = { vim.fn.getcurpos(shared_winid)[2], vim.fn.getcurpos(shared_winid)[3] }
  local selected_word = M.get_word_for_translate(cursor_position, shared_buffer, false)

  -- Table with dicts for the word.
  local values_dicts = CURRENT_DICTIONARY[M.get_dictionary_word(selected_word)]

  if values_dicts == nil then
    print("Слова <" .. selected_word .. "> нет в активном словаре.")
    return
  end

  --- Popup for comment
  local popup = M.get_comment_popup(shared_winid)

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
        { unpack(comment) })
      M.highlight_under_cusror(selected_word, cursor_position, shared_buffer)
      popup:mount()
      menu.border:set_text('top',
        "[" ..
        CURRENT_DICTIONARY_NAME ..
        "] " .. selected_word .. " " .. item.index .. "/" .. #values_dicts, "center")
    end,

    on_submit = function(item)
      vim.api.nvim_buf_clear_namespace(shared_buffer, 1, 0, -1)
      popup:unmount()
      M.translate_word(item, M.get_word_position(selected_word, cursor_position, shared_buffer),
        cursor_position[1],
        shared_buffer, selected_word)
      M.highlight_translated_words(shared_buffer)
    end,
  })
  menu:mount()
end

-- Draw comment popup for word with translate.
function M.draw_comment()
  local win_id = vim.api.nvim_get_current_win()
  local cursor = { vim.fn.getcurpos(win_id)[2], vim.fn.getcurpos(win_id)[3] }

  local word = M.get_word_for_translate(cursor, vim.api.nvim_get_current_buf(), false)

  local line = vim.fn.getline(cursor[1])
  local translate = line:sub(cursor[2], -1):match("%(([^%)]*)")

  local Popup = require("nui.popup")
  local popup = Popup({
    position = {
      row = M.COMMENT_POPUP_POSITION.row,
      col = M.COMMENT_POPUP_POSITION.col,
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
  if CURRENT_DICTIONARY[M.get_dictionary_word(word)] == nil then
    print("Данного слова нет в активном словаре.")
    return
  end
  for i = 1, #CURRENT_DICTIONARY[M.get_dictionary_word(word)] do
    if CURRENT_DICTIONARY[M.get_dictionary_word(word)][i].translate == translate then
      translate_num = i
      break
    end
  end
  if translate_num == nil then
    print("У слова нет перевода, либо задан несуществующий в активном словаре перевод.")
    return
  end

  local comment = {}
  for i in CURRENT_DICTIONARY[M.get_dictionary_word(word)][translate_num].comment:gmatch("[^%c]*") do
    if i ~= "" then
      table.insert(comment, i)
    end
  end
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false,
    { string.format("%s/%s", translate_num, #CURRENT_DICTIONARY[M.get_dictionary_word(word)]),
      unpack(comment) })

  popup:map("n", { "q", "<esc>" }, function() popup:unmount() end, { noremap = true })
  popup:mount()
end

-- Draw selector popup for select current dictionary.
function M.draw_current_dictionary_selecter()
  local win_id = vim.api.nvim_get_current_win()
  local current_buffer = vim.api.nvim_get_current_buf()

  local word = M.get_word_for_translate({ vim.fn.getcurpos(win_id)[2], vim.fn.getcurpos(win_id)[3] },
    current_buffer, true)
  local _word = vim.fn.expand("<cword>")

  local Menu = require("nui.menu")

  -- Place of word under cursor.
  local function get_lines()
    local function get_keyword_num(dict)
      local counter = 0
      for _, _ in pairs(dict) do
        counter = counter + 1
      end
      return counter
    end
    local consist_word = nil
    local items = {}
    for i, v in ipairs(ALL_DICTS) do
      local item = nil
      consist_word = "" -- Mark word existence in dictionary.

      for index, value in ipairs(word) do
        local word_pos_string = ""

        for w in value:gmatch("%a+") do
          if w == _word then
            word_pos_string = word_pos_string .. "■"
          else
            word_pos_string = word_pos_string .. "□"
          end
        end

        if v[1][M.get_dictionary_word(value)] ~= nil then
          consist_word = M.MARK_WORD_EXISTENCE .. " " .. word_pos_string
          break
        end
      end

      -- Check highlight colour for dictionary name.
      if v[3] ~= nil then
        local NuiLine = require("nui.line")
        local line = NuiLine()
        vim.cmd(":highlight " .. "dict_colour" .. i .. " guifg=" .. v[3])
        line:append(v[2] .. " [" .. get_keyword_num(v[1]) .. "] " .. consist_word,
          "dict_colour" .. i)
        item = Menu.item(line, v)
      else
        item = Menu.item(v[2] .. " [" .. get_keyword_num(v[1]) .. "] " .. consist_word, v)
      end

      table.insert(items, item)
    end


    -- Arrange dictionaries in alphabetical order
    table.sort(items, function(a, b) return a[2] < b[2] end)
    return items
  end

  local popup_options = {
    relative = "win",

    size = {
      width = M.CURRENT_DICTIONARY_MENU_SIZE.col,
      height = M.CURRENT_DICTIONARY_MENU_SIZE.row,
    },

    position = {
      row = M.CURRENT_DICTIONARY_MENU_POSITION.row,
      col = M.CURRENT_DICTIONARY_MENU_POSITION.col,
    },

    border = {
      style = "rounded",
      text = {
        top = CURRENT_DICTIONARY_NAME or "Нет активного словаря",
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
      M.highlight_words()
      M.highlight_translated_words(current_buffer)
    end,
  })
  menu:mount()
end

return M
