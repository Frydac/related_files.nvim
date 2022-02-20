local from_expr = require('related_files').pargen_from_expression
return {
    -- Describe types of files by provinding a name/id, parser function and
    -- generator function (aka pargen).
    -- Alternatively for a lot of simple cases, you can use the
    -- 'pargen_from_expression' helper function that implements a mini DSL to
    -- generate the parser/generator pair.
    pargens = {
        from_expr("source", "{parent}/{name}.py"),
        from_expr("test", "{parent}/{name}_test.py")
    },
    -- Specify which pargen relates to which with following effect:
    -- when on a source file: '<leader>2' -> to go to (or create) the related test file
    -- when on a test file: '<leader>1' -> to go to (or create) the related source file
    relations = {{"source", "test"}}
}
