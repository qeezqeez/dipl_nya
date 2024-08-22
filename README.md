Установка плагина:
Файл dipl.nvim поместить в ~/.config/nvim/lua/.
В init.lua в директории ~/.config/nvim/ добавить зависимость при помощи mini:

add({ source = "MunifTanjim/nui.nvim"})

После чего запускаем сам плагин:

require("dipl").setup {
  DICTIONARY_PATH = "path/to/dict", // полный путь до словаря на вашем устройстве
  DEFAULT_COLOUR = "#ffffff", // цвет для слов с наличием перевода
  COLOUR_FOR_CHOICE = "#ffffff", // цвет фона для слова, когда вы выбираете перевод  
}


Стандартные маппинги для плагина:
<C-l> - включить плагин (перезагрузить словарь)
<C-j> - выключить всю подсветку 
<C-k> - открыть меню выбора перевода

