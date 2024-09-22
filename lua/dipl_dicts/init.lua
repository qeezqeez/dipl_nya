local DICTIONARIES = {}
local files = vim.api.nvim_get_runtime_file("lua/dipl_dicts/*.lua", true)
for i = 1, #files do
  local mod_name = files[i]:match("[^%/]*$"):match("[^%.]*")
  local dict, dict_name
  if mod_name ~= "init" then
    dict, dict_name = unpack(require("dipl_dicts." .. mod_name))

    table.insert(DICTIONARIES, { dict, dict_name })
    package.loaded["dipl_dicts." .. mod_name] = nil
  end
end


return DICTIONARIES
