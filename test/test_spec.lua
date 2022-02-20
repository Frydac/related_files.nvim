-- describe("some basics", function()
--
--   local bello = function(boo)
--     return "bello " .. boo
--   end
--
--   local bounter
--
--   before_each(function()
--     bounter = 0
--   end)
--
--   it("some test", function()
--   bounter = 100
--     assert.equals("bello Brian", bello("Brian"))
--   end)
--
--   it("some other test", function()
--     assert.equals(0, bounter)
--   end)
-- end)

describe("related_files/expression test parse_expression", function()
    local exp = require('related_files/expression')
    print("first")

    before_each(function()
        print('before each')
    end)

    it("lua source", function()
        local dn_infix, bn_prefix, bn_postfix = exp.parse_expression('{parent}/lua/{namespace}/{name}.lua')
        assert.equals(dn_infix, "lua")
        assert.equals(bn_prefix, "")
        assert.equals(bn_postfix, ".lua")
    end)
    it("lua test", function()
        local dn_infix, bn_prefix, bn_postfix = exp.parse_expression('{parent}/lua/test/{namespace}/{name}_spec.lua')
        assert.equals(dn_infix, "lua/test")
        assert.equals(bn_prefix, "")
        assert.equals(bn_postfix, "_spec.lua")
    end)
end)
