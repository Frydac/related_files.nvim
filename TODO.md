* add support for multiple related_files_info.lua in ancestors and global?
  * multiple levels -> search for all of them
  * first try to parse with all nearest parsers then all further parsers
  * if nearest parser hits, it can also be related to further parser?
* make related_files_info.lua for auro
* check for and use notify.nvim
* documentation
* deal with errors
  * errors in related_files_info.lua
  * filename not matching any parsers
  * use pcall()
* create filename class using this info
  * add module/supermodule
* create luasnip snippets
  * init functions, c/h/cpp/hpp/tests rb_story/script/qc/release
  * convert all existing snippets? some can be copy pasted?
* make resolve multiple parser matches part of related_files_info.lua?

* could
  * when multiple matches, cache chosen match and add option to review current option
    * maybe add priority to pargens somehow?
  * more caching in general, when there is noticable performance impact
  * only add relevant keymappings on buffer creation
    * much more overhead

