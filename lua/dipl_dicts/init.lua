---@type table<Dictionary>
local DICTIONARIES = {}

-- Metatable. Consist word translates.
---@class Word
---@field Translations table -- Translations by position.
local Word = {
  -- Consist word translates by key. Translations[[key]] return table with
  -- following structure {translate = "", colour = "", comment = ""}
  Translations = {}
}

Word.__index = Word

-- Add new translate for the word in dictionary.
---@param key string -- Key for word.
---@param translate string -- Word translate.
---@param colour string -- Colour for highlight translate in "#000000" format.
---@param comment string -- Comment for translate.
function Word:add_translate(key, translate, colour, comment)
  key = key or "default_key"

  self.Translations[key] = {}
  local ts = self.Translations[key]

  ts.translate = translate or "default_translate"
  ts.colour = colour or "#ff0000"
  ts.comment = comment or "default_comment"
end

-- Delete translate for the word in dictionary.
---@param key string -- Key for word.
function Word:delete_translate(key)
  self.Translations[key] = nil
end

-- Return new Word instance.
---@return Word
function Word:new()
  return setmetatable({}, self)
end

-- Metatable. Consist Word instances.
---@class Dictionary
---@field Name string
---@field Colour string
---@field File_name string
---@field Words table<Word>
local Dictionary = {
  Name = "",
  Colour = "",
  File_name = "",
  Words = {}
}

Dictionary.__index = Dictionary

-- Return table with Word.
---@return table<Word>
function Dictionary:get_words()
  return self.Words
end

-- Return new Dictionary instance.
---@return Dictionary
function Dictionary:new()
  return setmetatable({}, self)
end

-- Read and load dictionary files in lua/dipl_dicts.
local files = vim.api.nvim_get_runtime_file("lua/dipl_dicts/*.lua", true)
for i = 1, #files do
  local mod_name = files[i]:match("[^%/%\\]*$"):match("[^%.]*")
  if mod_name ~= "init" then
    local dict_items, dict_name, dict_colour = unpack(require("dipl_dicts." .. mod_name))

    if dict_name ~= nil then -- Dicts without name is unused.
      DICTIONARIES[dict_name] = Dictionary:new()
      ---@type Dictionary
      local dt = DICTIONARIES[dict_name]

      dt.Name = dict_name
      dt.Colour = dict_colour
      dt.File_name = mod_name

      for k, v in pairs(dict_items) do
        local word = Word:new()
        dt.Words[k] = word

        for _, wv in ipairs(v) do
          word:add_translate(wv.key, wv.translate, wv.colour, wv.comment)
        end
      end
    end

    package.loaded["dipl_dicts." .. mod_name] = nil
  end
end


return DICTIONARIES
