--[[

Functionality to find/load the related_files_info describing the
parsers/generators for files and relations between files.

]]--

local M = {}

local path = require('related_files.util.path')
local print_error = require('related_files.util').print_error

local basename_info = ".related_files_info.lua"

-- Search for all .related_files_info.lua files in the parent dirs of filename
function M.find_related_file_infos(filename)
    filename = path.absolute(filename)
    local root = path.get_root(filename)
    local dir = path.dirname(filename)

    local related_file_info_fns = nil
    while dir ~= root do
        local fn_info = dir.."/"..basename_info
        if path.exists(fn_info) then
            related_file_info_fns = related_file_info_fns or {}
            table.insert(related_file_info_fns, fn_info)
        end
        dir = path.dirname(dir)
    end
    return related_file_info_fns
end

-- Expecting filename to be a .related_files_info.lua
function M.load_related_file_info(filename)
    local info, err = loadfile(filename)
    if not info then
        print_error("Can't load '"..filename.."'\n"..err)
        return nil
    end
    return info()
end

function M.find_and_load_related_file_info(filename)
    -- find info
    local fn_info = M.find_related_file_infos(filename)
    if not fn_info or #fn_info == 0 then
        print_error("Can't find a "..basename_info.." in any parent dir of '"..filename.."'")
        return nil
    end
    local related_files_info = M.load_related_file_info(fn_info[1])
    return related_files_info
end

return M
