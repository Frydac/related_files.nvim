local from_expr = require('related_files').pargen_from_expression
return {
    -- We only onverride one pargen, we use the same name so the "relations"
    -- table from the parent can be used.
    -- (imagine most modules use "include" but this one module uses "inc" in stead)
    pargens = {
        from_expr("public_hpp", "{parent}/inc/{namespace}/{name}.hpp"),
    }
}
