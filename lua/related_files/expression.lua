local M = {}

-- Break expression into parts from which we can generate a parser and generator.
--
-- Expression should have form like this:
--   |  A    |    B    |     C     |    D   |  E  |   F     |
--  "{parent}/([%w_/]+)/{namespace}/([%w_]*){name}([%w_%.]*)"
-- With:
-- A = related files have some common parent dir.
-- B = some unique dir that indicates the end of {parent} and begin of
--  {namespace} or {name}.
--  When {namespace} exists, this has to be non-emtpy!
-- C = optional namespace, also when exists (in expression), can be empty (in filename)
-- A + B + C = file directory
-- D = prefix part of the file basename, before the common part of the basename. Optional
-- E = common part of file basename
-- F = postfix part of the file basename, after the common part of the
-- basename.
--
-- This function parses a string that conforms to the the above expression and
-- returns, B, D and F
--
-- @return dn_infix (B)
--   dirname infix: Pattern indicating end of {parent} and begin of {namespace} or
--   {name}. When {namespace} exists, this has to be non-emtpy.
--   TODO: allow for `.git` or some sentinel file to be the indicator of the namespace?
-- @return bn_prefix (D)
--   basename prefix: optional pattern before {name} (which is part of the
--   file's basename), can be empty
-- @return bn_postfix (F)
--   basename postfix: pattern after {name} but part of the file's
--   basename (including extension), can be emtpy (not tested).
--   TODO: add more error checks and better error messages
function M.parse_expression(expression)
    local dn_infix, bn_prefix, bn_postfix = nil, nil, nil

    -- There aren't optional capture groups, and {namespace} is optional, I
    -- solve this by having 2 match patterns, one for each case. (this doesn't
    -- scale, but will do for now, and I think it is easy to read).
    local has_namespace = not not string.find(expression, "{namespace}")

    if has_namespace then
        dn_infix, bn_prefix, bn_postfix = string.match(expression, '^{parent}/([%w_/]+){namespace}/([%w_]*){name}([%w_%.]*)$')
        assert(dn_infix, "Can't parse expression: " .. expression)
    else
        dn_infix, bn_prefix, bn_postfix = string.match(expression, '^{parent}([%w_/]*)/([%w_]*){name}([%w_%.]*)$')
        assert(bn_prefix, "Can't parse expression: " .. expression)
    end

    return dn_infix, bn_prefix, bn_postfix
end

-- Create parser and generator for given expression
-- TODO: filetype not needed?
function M.pargen_from_expression(name, expression, vim_filetype)

    local dn_infix, bn_prefix, bn_postfix = M.parse_expression(expression)

    -- print("name: "..name)
    -- print("expression: "..expression)
    -- print("dn_infix: '"..dn_infix.."'")
    -- assert(dn_infix ~= "", "There need to be a part between parent and namespace")
    -- print("bn_prefix: '"..bn_prefix.."'")
    -- print("bn_postfix: '"..bn_postfix.."'\n")

    -- bn_postfix is not optional

    local pargen = {}

    pargen.parser = function (filename)
        -- print("pargen.name: "..pargen.name)
        -- print("filename: "..filename)

        -- common representation, this is the data that is the output of a parser,
        -- and servers as input for a generator
        local inter_rep = {
            parent = "",
            namespace = "",
            name = ""
        }

        pargen.vim_filetype = vim_filetype
        pargen.name = name
        pargen.expression = expression

        -- Splitting up the parsing as the namespace can be empty and there are no optional capture groups.
        -- probably more efficient way to do this, but this seems to work
        do
            local parent_pattern = "^(.*/)"..dn_infix
            inter_rep.parent = string.match(filename, parent_pattern)
            if not inter_rep.parent then
                -- print("Pargen "..pargen.name.." can't parse parent for filename: " ..filename)
                return nil
            end

            if dn_infix and #dn_infix > 0 then
                local namespace_pattern = "/"..dn_infix.."(/?.*/)"
                -- can be empty if no namespace
                inter_rep.namespace = string.match(filename, namespace_pattern) or ""
            end

            local basename_pattern = "/"..bn_prefix.."([^/]*)"..bn_postfix.."$"
            inter_rep.name = string.match(filename, basename_pattern)

            if not inter_rep.name then
                -- print("Pargen "..pargen.name.." can't parse name for filename: " ..filename)
                return nil
            end
        end

        -- print("Pargen "..pargen.name..":")
        -- print(" parent: "..inter_rep.parent)
        -- print(" namespace: '"..inter_rep.namespace.."'")
        -- print(" name: "..inter_rep.name)
        -- print()

        return inter_rep
    end

    pargen.generator = function (inter_rep)
        local filename = ""
        filename = inter_rep.parent..dn_infix..inter_rep.namespace
        filename = bn_prefix == "" and filename or filename..bn_prefix
        filename = filename..inter_rep.name..bn_postfix
        -- print(name.." generator filename: "..filename)
        return filename
    end

    return pargen
end

return M
