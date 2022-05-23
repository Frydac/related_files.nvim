local tprint = require('related_files.util').tprint
local rf = require('related_files.related_files')
local rf_info = require('related_files.info')
local path = require('related_files.util.path')
local print_error = require('related_files.util').print_error
local print_warning = require('related_files.util').print_warning

local M = {}
M.info = rf_info
-- M.file = require('related_files.file')

M.pargen_from_expression = require('related_files.expression').pargen_from_expression

local function create_and_open_one_of(filenames)
    if #filenames == 1 then
        local fn = filenames[1]
        vim.ui.input(
            { prompt = "Related file '"..fn.."' doesn't exist, create? (y/esc): " },
            function (input)
                if input == "y" then
                    path.touch(fn)
                    vim.cmd("silent edit "..fn)
                    print("Created new file: "..fn)
                end
            end
        )
    elseif #filenames > 1 then
        vim.ui.select(
            filenames ,
            { prompt = "No related file exists, create one of these candidates?" },
            function(fn, _)
                if fn then
                    path.touch(fn)
                    vim.cmd("silent edit "..fn)
                    print("Created new file: "..fn)
                end
            end
        )
    end
end

-- returns pargen and parsed intermediate_representation (inter_rep) for filename
function M.get_pargen(filename)
    local related_files_info = M.info.find_and_load_related_file_info(filename)
    local matching_pargens = rf.find_all_matching_pargen_parsers(related_files_info.pargens, filename)
    local matching_pargen = rf.choose_from_matching_pargens(matching_pargens, filename)
    return matching_pargen
end


function M.get_related_file_info(filename)
    -- find info
    local fn_info = rf_info.find_related_file_infos(filename)
    L("fn_info: ", fn_info)
    if not fn_info or #fn_info == 0 then
        print_error("Can't find a .related_file_info.lua in any parent dir of '"..filename.."'")
        return nil
    end
    local related_files_info = rf_info.load_related_file_info(fn_info[1])
    if not related_files_info then
        print_error("Can't load info from '"..fn_info[1].."'")
        return nil
    end
    return related_files_info
end

function M.open_or_create_related_file(from_filename, to_index)
    -- find info
    local related_files_info = M.info.find_and_load_related_file_info(from_filename)
    if not related_files_info then return nil end

    -- find related candidates
    local fns_exist, fns_non_exist = rf.find_existing_related_candidates(from_filename, related_files_info, to_index)
    if not fns_exist then return nil end

    -- Decide which to open_or_create
    if #fns_exist == 1 then
        -- one existing related file -> open
        vim.cmd("silent edit "..fns_exist[1])
    elseif #fns_exist > 1 then
        -- multiple existing related files -> open one
        vim.ui.select(
            fns_exist ,
            { prompt = "Multiple related files exist, open one of these?" },
            function(fn, _)
                if fn then
                    vim.cmd("silent edit "..fn)
                    print("Created new file: "..fn)
                end
            end
        )
    else
        -- no existing related files -> create one of the non_existing candidates
        create_and_open_one_of(fns_non_exist)
    end
end

function M.print_log_info(to_index)
    local current_buffer_handle = 0
    local from_filename = vim.api.nvim_buf_get_name(current_buffer_handle)

    -- find info
    local fn_info = rf_info.find_related_file_infos(from_filename)
    if #fn_info == 0 then
        print("Can't find a .related_file_info.lua in any parent dir of '"..from_filename.."'")
        return nil
    end
    local related_files_info = rf_info.load_related_file_info(fn_info)
    assert(related_files_info, "Can't load info from '"..fn_info.."'")

    local info_log = rf.info_log(from_filename, related_files_info, to_index)
    print(info_log.to_string())
end

-- Use current buffer as source
function M.open_or_create_related_file_buf(to_index)
    -- print('get_or_create_related_file_buf(index): '.. to_index)
    local current_buffer_handle = 0
    M.open_or_create_related_file(vim.api.nvim_buf_get_name(current_buffer_handle), to_index)
end

-- namespace Related Files
RF = {}

-- Default options
RF.default_opts = {
    __index = function(_, key) return RF.default_opts[key] end,
    nr_keymaps = 5, -- The max number of indexes used in the relations specification of your .related_files_info.lua
    enable_default_keymaps = true  -- Set the default mappings to <leader>1 to <leader><nr_keymaps>
}

local function set_keymaps(opts)
    RF.current_opts = opts
    local function set_plug_keymaps(nr_keymaps)
        for keymap_ix = 1, nr_keymaps do
            vim.api.nvim_set_keymap('n', '<Plug>RelatedFileGetOrCreate'..keymap_ix, '<cmd>lua require("related_files").open_or_create_related_file_buf('..keymap_ix..')<cr>', {})
        end
    end
    local function set_default_keymaps(nr_keymaps)
        for keymap_ix = 1, nr_keymaps do
            vim.api.nvim_set_keymap('n', '<leader>'..keymap_ix, '<Plug>RelatedFileGetOrCreate'..keymap_ix, {})
        end
    end

    set_plug_keymaps(opts.nr_keymaps)
    if (opts.enable_default_keymaps) then
        set_default_keymaps(opts.nr_keymaps)
    end

    -- local function set_debug_keymaps()
    --     vim.api.nvim_set_keymap('n', '<leader><leader>d', '<cmd>lua require("related_files").debug()<cr>', {})
    -- end
    -- set_debug_keymaps()
end

local function set_commands(opts)
    -- rf.info_log
    local cmd = string.format("command! RFInfo :lua print(require('related_files.related_files').info_log_buf(%d).to_string())", opts.nr_keymaps)
    vim.cmd(cmd)
end

function M.setup(opts)
    opts = opts or {}
    setmetatable(opts, RF.default_opts)

    set_keymaps(opts)
    set_commands(opts)
end

return M
