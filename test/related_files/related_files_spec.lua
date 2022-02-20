-- local function script_path()
--    local str = debug.getinfo(2, "S").source:sub(2)
--    return str:match("(.*/)")
-- end

describe("related_files/related_files test", function()
    local rf = require('related_files.related_files')
    local script_fn = debug.getinfo(1, "S")
    script_fn = script_fn.source:sub(2)
    L("script_fn: ", script_fn)

    local fn = '/home/emile/repos/all/comp/espcap/test/private/auro/espcap/v2/RoomCentricPanner_tests.cpp'
    it("tdd", function ()
        print(rf.info_log(fn, 5).to_string())
        print("1")
        print("2")
    end)
end)
