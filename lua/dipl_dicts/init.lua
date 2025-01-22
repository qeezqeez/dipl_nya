local DICTIONARIES = {}

---@class Word
local Word = {
  Translations = {}
}

-- Add new translate to the word in dictionary.
---@param key string -- Key for word.
---@param translate string -- Word translate.
---@param colour string -- Colour for highlight translate in "#000000" format.
---@param comment string -- Comment for translate.
function Word:add_translate(key, translate, colour, comment)
  local val = {}
  val.key = key or "default_key"
  val.translate = translate or "default_translate"
  val.colour = colour or "#ff0000"
  val.comment = comment or "default_comment"

  table.insert(self.Translations, val)
end

---@return Word
function Word:new()
  local instance = {}
  for k, v in pairs(self) do
    instance[k] = v
  end

  -- Prevent instances from being created from an instance.
  instance.new = nil

  return setmetatable(instance, self)
end

---@class Dictionary
local Dictionary = {
  Name = "",
  Colour = "",
  File_Name = ""
}

function Dictionary:set_name(name)
  self.Name = name
end

---@return string
function Dictionary:get_name()
  return self.Name
end

---@param colour string -- Colour in "#000000" format.
function Dictionary:set_colour(colour)
  self.Colour = colour
end

---@return string
function Dictionary:get_colour()
  return self.Colour
end

-- Add word to dictionary.
---@param word Word
function Dictionary:add_word(word)
end

-- Cast new Dictionary instance.
---@return Dictionary
function Dictionary:new()
  local instance = {}
  for k, v in pairs(self) do
    instance[k] = v
  end

  -- Prevent instances from being created from an instance.
  instance.new = nil

  return setmetatable(instance, self)
end

local test = Dictionary:new()
test:set_name("Sueta")
print(test)

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
