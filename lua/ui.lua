local M = {}

-- Return completed comment popup for menu
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

-- Drawing window with translate variants
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

return M
