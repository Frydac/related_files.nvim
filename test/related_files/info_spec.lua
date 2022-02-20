local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local function repository_dir()
    local path = require('related_files.util.path')
    local sentinel = ".git"
    local dir = script_path()
    local root = path.get_root(dir)
    assert(root)

    while dir ~= root do
        dir = path.dirname(dir)
        local git_fn = dir.."/"..sentinel
        if path.exists(git_fn) then
            return dir
        end
    end
    return nil
end

describe("related_files/info test", function()
    local info = require('related_files/info')
    local path = require('related_files.util.path')
    local script_fn = script_path()
    local repo_dir = repository_dir()

    it ("find the info for this test file repo", function ()
        local fn_infos = info.find_related_file_infos(script_fn)
        -- print("fn_info: "..fn_info)
        local fn_expected = path.dirname(path.dirname(path.dirname(script_fn))).."/.related_files_info.lua"
        -- L("fn_infos: ", fn_infos)
        -- print("_")
        assert.equal(1, #fn_infos)
        assert.equal(fn_expected, fn_infos[1])
    end)

    it ("find the infor for an example with nested info files", function ()
        local fn = repo_dir.."/test/examples/004_nested_related_file_infos/module_b/inc/ns1/file_b.hpp"
        local fns_info = info.find_related_file_infos(fn)
        -- L("fns_info: ", fns_info)
        local expected = { repo_dir.."/test/examples/004_nested_related_file_infos/.related_files_info.lua", repo_dir.."/.related_files_info.lua" }
        assert.equal(fns_info[1], expected[1])
        assert.equal(fns_info[2], expected[2])
        -- print("__")
    end)

    it ("tdd", function ()
        print(rf.log_info(script_fn))
    end)
end)



