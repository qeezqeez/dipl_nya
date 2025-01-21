local DICTIONARIES = {}

---@class Dictionary
local Dictionary = {}

function Dictionary:set_name(name)
  self.Name = name
end

function Dictionary:get_name()
  return self.Name
end

function Dictionary:add_word(word)
end

---@return Dictionary
-- Cast new Dictionary instance.
function Dictionary:new()
  local instance = {}
  for k, v in pairs(self) do
    instance[k] = v
  end

  return instance
end

local files = vim.api.nvim_get_runtime_file("lua/dipl_dicts/*.lua", true)
for i = 1, #files do
  local mod_name = files[i]:match("[^%/%\\]*$"):match("[^%.]*")
  if mod_name ~= "init" then
    local dict, dict_name, dict_colour = unpack(require("dipl_dicts." .. mod_name))

    if dict_name ~= nil then -- Dicts without name is unused.
      table.insert(DICTIONARIES, { dict, dict_name, dict_colour })
    end

    package.loaded["dipl_dicts." .. mod_name] = nil
  end
end


return DICTIONARIES
