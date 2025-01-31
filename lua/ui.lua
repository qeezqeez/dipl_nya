local M = {}

Dipl = require("dipl")

-- Return completed comment popup for menu.
---@return NuiPopup
function M.get_comment_popup(win_id)
  local Popup = require("nui.popup")

  local popup = Popup({
    relative = {
      type = "win",
      winid = win_id,
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

-- Init and return menu window (popup)
---@param word string -- In "word_" format.
---@param cursor_pos table -- Cursor position.
---@param word_pos table -- Word position {start = col_num, end = col_num}
---@param win_id integer -- Window id where word is..
---@param buff_id integer -- Buffer id where word is.
---@param dictionary Dictionary -- Current dictionary. Should be nil if not selected.
---@return NuiMenu | nil
function M.init_menu(word, cursor_pos, word_pos, win_id, buff_id, dictionary)
  if dictionary == nil then
    print("Вы не выбрали активный словарь.")
    return nil
  end

  if dictionary.Words[word] == nil then
    print("Слова <" .. word .. "> нет в активном словаре.")
    return nil
  end

  ---@type Word
  local Dictionary_word = dictionary.Words[word]

  -- Popup for comment.
  local popup = M.get_comment_popup(win_id)

  -- Menu constructor.
  local Menu = require("nui.menu")

  -- Return items for menu.
  ---@param word_instance Word
  local function get_menu_items(word_instance)
    -- TODO: Better do item indexing in another place.

    -- Item index for display translate number in menu popup.
    local item_index = 0
    local menu_items = {}
    for key, value in word_instance.Translations do
      item_index = item_index + 1
      local str = key .. " " .. value.translate

      -- Use nui.line for simple highlight.
      local NuiLine = require("nui.line")
      ---@type NuiLine
      local line = NuiLine()
      -- Do color for translation line.
      vim.cmd(":highlight " .. "colour" .. item_index .. " guifg=" .. value.colour)
      line:append(str, "colour" .. item_index)

      -- Add info line and values of translations.
      table.insert(menu_items, Menu.item(line, value))
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
        top = "[" .. dictionary.Name .. "] " .. Dipl.get_text_word(word),
        top_align = "center",
      },
    },

    win_options = {
      winhighlight = "Normal:Normal",
    }
  }
  local menu = Menu(popup_options, {
    lines     = get_menu_items(dictionary.Words[word]),
    keymap    = {
      focus_next = { "j", "<Down>" },
      focus_prev = { "k", "<Up>" },
      close = { "<Esc>", "q" },
      submit = { "<CR>" },
    },
    on_close  = function()
      if popup then
        popup:unmount()
      end
      vim.api.nvim_buf_clear_namespace(buff_id, 1, 0, -1)
      Dipl.highlight_translated_words(buff_id)
    end,

    on_change = function(item, menu)
      vim.api.nvim_buf_clear_namespace(buff_id, 1, 0, 1)
      local comment = {}
      for i in item.comment do end
    end,
    on_submit = function(item) end
  })
end

return M
