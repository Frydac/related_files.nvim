
local expr = require('related_files.expression')

describe("expressiont ests", function()
    it ("with namespace", function ()
        local pargen = expr.pargen_from_expression("test", "{parent}/test/private/{namespace}/Room{name}_tests.cpp")
        L("pargen: ", pargen)

        do
            local fn = "/home/emile/repos/all/comp/espcap/test/private/aur-o/esp_cap/v 2/Room  Centric-P_a_nner_tests.cpp"
            local ir = pargen.parser(fn)
            L("fn: ", fn)
            L("=> ir: ", ir)
            print()
            if ir then
                local new_fn = pargen.generator(ir)
                L("new_fn: ", new_fn)
                assert.equal(fn, new_fn)
            end
        end

        do
            local fn = "/home/emile/repos/all/comp/espcap/test/private/RoomCentricPanner_tests.cpp"
            local ir = pargen.parser(fn)
            L("fn: ", fn)
            L("=> ir: ", ir)
            print()
            if ir then
                local new_fn = pargen.generator(ir)
                L("new_fn: ", new_fn)
                assert.equal(fn, new_fn)
            end
        end

        print("...")
    end)

    it ("without namespace", function ()
        local pargen = expr.pargen_from_expression("test", "{parent}/Room{name}_tests.cpp")
        L("pargen: ", pargen)

        do
            local fn = "/home/emile/repos/all/comp/espcap/test/private/RoomCentricPanner_tests.cpp"
            local ir = pargen.parser(fn)
            L("fn: ", fn)
            L("=> ir: ", ir)
            print()
            if ir then
                local new_fn = pargen.generator(ir)
                L("new_fn: ", new_fn)
                assert.equal(fn, new_fn)
            end
        end
        print("...")
    end)
end)
