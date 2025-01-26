local M = {}

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

---@param word string
---@param cursor_pos table
---@param word_pos table
---@param win_id integer
---@param buff_id integer
---@param dictionary Dictionary
---@return NuiMenu | nil
function M.init_menu(word, cursor_pos, word_pos, win_id, buff_id, dictionary)
  if dictionary == nil then
    return nil
  end
end

return M
