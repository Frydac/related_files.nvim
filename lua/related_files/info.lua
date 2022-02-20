--[[

Functionality to find/load the related_files_info describing the
parsers/generators for files and relations between files.

]]--

local M = {}

local path = require('related_files.util.path')

-- Search for all .related_files_info.lua files in the parent dirs of filename
function M.find_related_file_infos(filename)
    filename = path.absolute(filename)
    local root = path.get_root(filename)
    local dir = path.dirname(filename)
    local basename_info = ".related_files_info.lua"

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
        print("Can't load '"..filename.."'")
        print(err)
        return nil
    end
    return info()
end

return M
