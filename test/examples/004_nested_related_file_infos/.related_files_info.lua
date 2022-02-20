local from_expr = require('related_files').pargen_from_expression
return {
    -- We have taken inspiration from the 003_ example, but reduced to show of
    -- the nested feature more clearly.
    pargens = {
        from_expr("private_cpp", "{parent}/src/{namespace}/{name}.cpp"),
        from_expr("public_hpp", "{parent}/include/{namespace}/{name}.hpp"),
    },
    relations = {
        {"public_hpp", "private_cpp"}
    }
}
