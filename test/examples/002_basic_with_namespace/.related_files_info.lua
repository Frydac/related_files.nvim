local from_expr = require('related_files').pargen_from_expression
return {
    pargens = {
        -- When using a {namespace} the pargen_from_expression() function
        -- expects some part between {parent} and {namespace} in order to know
        -- when the namespace begins.
        -- If this doesn't work for your usecase (e.g. the separator is part of
        -- the namespace, or you want to use a git repository, or sentinel/root
        -- file as namespace start), you need to write your own
        -- parser/generator pair.
        from_expr("source", "{parent}/002_basic_with_namespace/{namespace}/{name}.py"),
        -- Note: "test" would also work without the test file being in a
        -- seperate test directory.
        from_expr("test", "{parent}/002_basic_with_namespace/test/{namespace}/test_{name}.py")
    },
    relations = {{"source", "test"}}
}
