local from_exp = require('related_files').pargen_from_expression
return {
    pargens = {
        from_exp("source", "{parent}/lua/{namespace}/{name}.lua"),
        from_exp("test", "{parent}/test/{namespace}/{name}_spec.lua")
    },
    -- TODO: make work with 'nil' iso empty string
    relations = {{"source", "", "test"}}
}
