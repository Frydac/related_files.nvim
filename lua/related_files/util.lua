
local M = {}

-- table print: print table with optional name
-- if array isn't a table, just print the value
function M.tprint (tbl, name)

    local indent_str = "  "
    local function tprint_recurse(tbl_, indent)
        for k, v in pairs(tbl_) do
            local formatting = string.rep(indent_str, indent) .. "["..k.."]: "
            if type(v) == "table" then
                print(formatting)
                tprint_recurse(v, indent+1)
            else
                print(formatting .. tostring(v))
            end
        end
    end

    local indent = 0

    if name then
        print(name)
        indent = 1
    end

    if type(tbl) == 'table' then
        tprint_recurse(tbl, indent)
    else
        print(indent_str..tostring(tbl))
    end
end

function M.print_warning(msg)
    local ok, notify = pcall(require, 'notify')
    -- local ok = nil
    if ok then
        local title = "RelatedFiles"
        notify.notify(msg, vim.log.levels.WARN, {title = title})
    else
        local rf_msg = "RelatedFiles warning:\n"..msg
        vim.api.nvim_echo({{rf_msg, "WarningMsg"}}, true, {})
    end
end

function M.print_error(msg)
    local ok, notify = pcall(require, 'notify')
    -- local ok = nil
    if ok then
        local title = "RelatedFiles"
        notify.notify(msg, vim.log.levels.ERROR, {title = title})
    else
        local rf_msg = "RelatedFiles error:\n"..msg
        vim.api.nvim_echo({{rf_msg, "ErrorMsg"}}, true, {})
    end
end



-- TODO: remove, in Path now
function M.file_exists(filename)
   local f=io.open(filename,"r")
   if f~=nil then
       io.close(f)
       return true
   else
       return false
   end
end

function M.table_partition(array, predicate)
    local ok, not_ok = {}, {}
    for _, v in ipairs(array) do
        if predicate(v) then
            table.insert(ok, v)
        else
            table.insert(not_ok, v)
        end
    end
    return ok, not_ok
end

function M.table_min_elements(array, make_sortable_value)
    local min_elements_ = nil
    local min_el_val = nil
    for _, element in ipairs(array) do
        if not min_elements_ then
            min_elements_ = {element}
            min_el_val = make_sortable_value and make_sortable_value(element) or element
        else
            local cur_el_val = make_sortable_value and make_sortable_value(element) or element
            if min_el_val == cur_el_val then
                -- elements with the same value ar all returned
                table.insert(min_elements_, element)
            elseif cur_el_val < min_el_val then
                min_elements_ = {element}
            end
        end
    end
    return min_elements_
end

function M.table_find_element(array, predicate)
    for _, value in ipairs(array) do
        if predicate(value) then
            return value
        end
    end
    return nil
end

function M.table_contains(array, element)
    local result = M.table_find_element(array, function (value) return value == element end)
    return not not result
end

function M.table_index(array, element)
    -- NOTE: need to use pairs here, then it supportes array tables with nil
    -- entries, ipairs stops on a nil value, for example:
    -- local my_tbl = {'1', nil, nil, '4'}
    -- L("my_tbl: ", my_tbl)
    -- for i, v in pairs(my_tbl) do
    --     L("i: ", i)
    --     L("v: ", v)
    -- end

    for ix, value in pairs(array) do
        if value == element then
            return ix
        end
    end
    return nil
end


return M
