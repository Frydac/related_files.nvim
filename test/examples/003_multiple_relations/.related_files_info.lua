local from_expr = require('related_files').pargen_from_expression
return {
    pargens = {
        from_expr("private_h", "{parent}/src/{namespace}/{name}.h"),
        from_expr("private_c", "{parent}/src/{namespace}/{name}.c"),
        from_expr("private_hpp", "{parent}/src/{namespace}/{name}.hpp"),
        from_expr("private_cpp", "{parent}/src/{namespace}/{name}.cpp"),
        from_expr("public_h", "{parent}/include/{namespace}/{name}.h"),
        from_expr("public_hpp", "{parent}/include/{namespace}/{name}.hpp"),
    },
    relations = {
        {"private_h", "private_c"},
        {"private_h", "private_cpp"},
        {"private_hpp", "private_cpp"},

        {"public_h", "private_c"},
        {"public_h", "private_cpp"},
        {"public_hpp", "private_cpp"},
    }
}
