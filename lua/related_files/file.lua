package.loaded['related_files'] = nil
local rf = require('related_files')

local File = {
}

local function split_namespace(namespace)
        local result={}
        for dir in string.gmatch(namespace, "([^/]+)") do
                table.insert(result, dir)
        end
        return result
end

function File:new(filename)
    local obj = {}
    obj.path = filename
    obj.info = rf.get_pargen(obj.path)
    obj.name = obj.info.inter_rep.name
    obj.namespace = obj.info.inter_rep.namespace
    obj.namespaces = split_namespace(obj.namespace)
    obj.parent = obj.info.inter_rep.parent
    obj.basename = vim.fn.fnamemodify(obj.path, ":t")
    obj.ext = vim.fn.fnamemodify(obj.path, ":e")
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- @param keyindex 
--   Is the index in the relations table of the wanted related pargens as
--   define in the .related_files_info.lua for the current filename
function File:find_related_filenames(keyindex, only_existing_filenames)
    -- find all related pargens in this keyindex
    -- generate all filenames
    -- check if any exists
end

-- local file = File:new("/home/emile/.local/share/nvim/site/pack/packer/start/related_files.nvim/test/examples/001_basic/file_a.py")
-- local file = File:new("/home/emile/repos/all/fusion/cx/test/cpp14/private/auro/cx/v1/decoder/post_process/LinearInterpolator_tests.cpp")
--
--
-- print(vim.inspect(file))

return File
