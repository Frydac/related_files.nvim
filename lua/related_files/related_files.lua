local util = require('related_files.util')
local warning = util.print_warning
local info = require('related_files.info')

local M = {}

-- returns a list of pargens with the shortest non-emtpy namespace
local function find_mininal_non_empty_namespace(matching_pargens)
    local pargens_with_namespace = {}

    -- only consider pargen ir's with namespaces
    for _, pargen in ipairs(matching_pargens) do
        if #pargen.inter_rep.namespace > 0 then
            table.insert(pargens_with_namespace, pargen)
        end
    end

    -- find list of pargens with ir's with smallest namespace
    local min_non_empty_namespace = util.table_min_elements(pargens_with_namespace, function(pargen) return pargen.inter_rep.namespace end)
    return min_non_empty_namespace
end

-- Gets a list of pargens for which the parsers work for the given path, and
-- also contain the intermediate representation that comes from the parser. We
-- want to choose 1 of those 'matching pargens'.
-- TODO: this depends on what the intermediate representation looks like -> should be part of pargen?
-- TODO: make relove function an api callback
local function resolve_multiple_matching_pargens(matching_pargens)
    -- multiple parsers can parse the filename, this means that one parser's
    -- collection of paths it can parse intersects with the other. This is ok,
    -- but one is probably better than another, i.e. it gives more
    -- complete/accurate intermediate representation.
    -- TODO: explain the following better, with examples. I'm sure I missed usedcases, this might make it clearer.
    -- We choose:
    -- * with namespace over no namespace
    -- * shorter namespace over longer namespace (deeper path)
    -- * for same lenght namepsace -> the shortest basename
    local matching_pargen = nil
    table.sort(matching_pargens, function(lhs, rhs) return lhs.inter_rep.namespace < rhs.inter_rep.namespace end)
    local min_non_empty_namespace = find_mininal_non_empty_namespace(matching_pargens)
    if #min_non_empty_namespace == 1 then
        matching_pargen = min_non_empty_namespace[1]
    else
        -- if we have multiple with non-empty but equal length namespaces,
        -- search in those matching pargens, otherwise (all empty namespaces)
        -- search all matching pargens.
        local pargens_to_consider = #min_non_empty_namespace > 1 and min_non_empty_namespace or matching_pargens
        local min_name = util.table_min_elements(pargens_to_consider, function(match) return match.inter_rep.name end)
        assert(#min_name ~= 0)
        if #min_name > 1 then
            -- TODO: maybe ask user which one to choose?
            print("Two different parsers match the same filename with the same intermediate representation, dealing with this is not properly implemented. We just take the first one.")
        end
        matching_pargen = min_name[1]
    end
    return matching_pargen
end

-- Usually only one parser is correct, we choose one
function M.choose_from_matching_pargens(matching_pargens, filename)
    if #matching_pargens == 0 then
        -- no parser works for the filename (TODO: add info about upcoming info interface)
        warning(string.format("No related files parsers match filename: '%s'", filename))
        return nil
    elseif #matching_pargens == 1 then
        -- we have 1 matching parser, all is well
        return matching_pargens[1]
    else
        -- multipel matching parsers, we reduce it to one following some rules that seem to make sense for me.
        return resolve_multiple_matching_pargens(matching_pargens)
    end
end

-- @returns
--   * a list of pargens that are on relations_index in the defined
--     relations, and are related to matching_pargen_name
local function find_related_pargens(matching_pargen, related_files_info, relations_index)
    local related_pargens = {}
    for _, relation in ipairs(related_files_info.relations) do
        -- relation = list of related pargen names
        if relations_index > #relation then goto continue end
        local matching_pargen_ix = util.table_index(relation, matching_pargen.name)

        -- relation should contain the matching name, but the related pargen
        -- index we are looking for should not refer to the matching pargen
        -- (i.e. related to itself)
        if not matching_pargen_ix or matching_pargen_ix == relations_index then goto continue end

        -- we found a pargen name that is related on the target relations_index
        local target_pargen_name = relation[relations_index]

        -- however don't add a pargen that is already in the matching pargens list (relations can have duplicates)
        for _, related_pargen in ipairs(related_pargens) do
            if related_pargen.pargen.name == target_pargen_name then goto continue end
        end

        local related_pargen = util.table_find_element(related_files_info.pargens, function(pargen) return pargen.name == target_pargen_name end)
        if related_pargen then
            table.insert(related_pargens, {pargen = related_pargen, relation = relation})
        end

        ::continue::
    end
    return related_pargens
end

-- NOTE: returns a list of pairs {pargen, inter_rep}
function M.find_all_matching_pargen_parsers(pargens, filename)
    local matching_pargens = {}
    -- check all the parsers TODO: only use parsers for certain vim_filetype when defined
    for _, pargen in ipairs(pargens) do
        -- L("pargen.name: ", pargen.name)
        local intermediate_representation = pargen.parser(filename)
        -- L("intermediate_representation: ", intermediate_representation)
        if intermediate_representation then
            table.insert(matching_pargens, {inter_rep = intermediate_representation, pargen = pargen})
        end
    end
    return matching_pargens
end

local function generated_related_filenames(related_pargens, intermediate_representation)
    local related_filenames = {}
    for _, pargen in ipairs(related_pargens) do
        local related_filename = pargen.pargen.generator(intermediate_representation)
        table.insert(related_filenames, related_filename)
    end
    return related_filenames
end

function M.find_related_candidates(filename, related_files_info, relations_index)
    -- find 1 pargen that can parse (i.e. the match)
    local matching_pargens = M.find_all_matching_pargen_parsers(related_files_info.pargens, filename)
    local matching_pargen = M.choose_from_matching_pargens(matching_pargens, filename)
    if not matching_pargen then
        return nil
    end
    -- use matching_pargen's name to find related pargens
    -- candidates with.
    local related_pargens = find_related_pargens(matching_pargen.pargen, related_files_info, relations_index)
    if #related_pargens == 0 then
        warning("No related generator found for matching parser:\n name = "..matching_pargen.pargen.name.."\n expression = "..matching_pargen.pargen.expression.."\nto keymap index: "..relations_index)
    end
    local related_filenames = generated_related_filenames(related_pargens, matching_pargen.inter_rep)

    return related_filenames
end

-- @returns 2 arrays, one with existing related files, one with non-existing related files
function M.find_existing_related_candidates(filename, related_files_info, relations_index)
    local related_fns = M.find_related_candidates(filename, related_files_info, relations_index)
    if not related_fns then
        warning(string.format("Can't find related filenames for '%s' to keymap index '%d'", filename, relations_index))
        return nil
    end

    local file_exists = require('related_files.util.path').exists
    local related_existing_fns, related_non_existing_fns = util.table_partition(related_fns, file_exists)
    return related_existing_fns, related_non_existing_fns
end

-- function M.info_log_from_info(filename, related_files_info, to_index)
local log_table = {
    filename = "",
    data = {
        {
            fn_related_file_info = "",
            related_file_info = {},
            matching_parsers = {
                { pargen = {}, ir = {}, chosen = false },
                { pargen = {}, ir = {}, chosen = true }
            },
            related_fns = {
                keymap_ix_1 = {
                    {
                        fn = "",
                        relation = "",
                        pargen = {},
                    },
                    {
                        fn = "",
                        relation = "",
                        pargen = {},
                    },
                },
                keymap_ix_2 = {
                    -- ...
                }
            }
        },
        {
            fn_related_file_info = "",
            -- ...
        },
    }
}

-- TODO: move to own file?
function M.info_log(filename, nr_keymaps)
    local log_info = {}

    -- Gather all data
    log_info.filename = filename
    log_info.data = {}
    local fns_rf_info = info.find_related_file_infos(filename)
    for rf_info_ix, fn_rf_info in ipairs(fns_rf_info) do
        log_info.data[rf_info_ix] = {}
        local data = log_info.data[rf_info_ix]
        data.fn_related_file_info = fn_rf_info
        local related_file_info = info.load_related_file_info(fn_rf_info)
        -- data.related_file_info = related_file_info
        if related_file_info then

            -- parsers
            local matching_pargens = M.find_all_matching_pargen_parsers(related_file_info.pargens, filename)
            data.matching_pargens = matching_pargens
            if #matching_pargens == 0 then goto continue end
            local pargen_chosen = M.choose_from_matching_pargens(matching_pargens, filename)
            -- L("pargen_chosen: ", pargen_chosen)
            local ir = pargen_chosen.pargen.parser(filename)
            data.matching_pargens = {}
            for parser_ix, pargen in ipairs(matching_pargens) do
                -- L("parser_ix: ", parser_ix)
                -- L("pargen: ", pargen)
                data.matching_pargens[parser_ix] = {
                    -- ir = pargen == pargen_chosen and ir or pargen.pargen.parser(filename),
                    chosen = pargen == pargen_chosen,
                    pargen = pargen,
                }
            end

            -- generators
            data.related_fns = {}
            for keymap_ix = 1, nr_keymaps do
                data.related_fns["keymap_"..keymap_ix] = {}
                local related_pargens = find_related_pargens(pargen_chosen.pargen, related_file_info, keymap_ix)
                for rel_pargen_ix, rel_pargen in ipairs(related_pargens) do
                    data.related_fns["keymap_"..keymap_ix]["related_pargen_"..rel_pargen_ix] = {
                        generator_filename = rel_pargen.pargen.generator(pargen_chosen.inter_rep),
                        from_relation = rel_pargen.relation,
                        pargen = rel_pargen.pargen
                    }
                end
            end

        end

        ::continue::
    end

    -- log_info.related_files_info = info.load_related_file_info(log_info.fn_related_file_info)
    -- if log_info.related_files_info then
    --     log_info.matching_pargens = find_all_matching_pargen_parsers(log_info.related_files_info.pargens, filename)
    --     log_info.matching_pargen = choose_from_matching_pargens(log_info.matching_pargens, filename)
    --     if log_info.matching_pargen then
    --         log_info.related = {}
    --         for rel_ix = 1, nr_keymaps do
    --             local related_pargens = find_related_pargens(log_info.matching_pargen.pargen, log_info.related_files_info, rel_ix)
    --             if #related_pargens == 0 then goto continue end
    --             log_info.related[rel_ix] = {}
    --             for pargen_ix, related_pargen in ipairs(related_pargens) do
    --                 log_info.related[rel_ix][pargen_ix] = {}
    --                 log_info.related[rel_ix][pargen_ix].pargen = related_pargen
    --                 log_info.related[rel_ix][pargen_ix].filenames = {}
    --                 local fns = log_info.related[rel_ix][pargen_ix].filenames
    --                 local related_fns = generated_related_filenames({related_pargen}, log_info.matching_pargen.inter_rep)
    --                 local file_exists = require('related_files.util.path').exists
    --                 fns.existing, fns.non_existing = util.table_partition(related_fns, file_exists)
    --             end
    --             ::continue::
    --         end
    --     end
    -- end

    -- generate log message with all above info
    log_info.to_string = function()
        -- util.tprint(log_info, "log_info")
        L("log_info", log_info)
        -- local output = ""
        -- local function log(msg) output = output..msg.."\n" end
        --
        -- log("Related Files Info")
        -- log(string.format(" starting filename:                 %s",filename))
        -- log(string.format(" location '.related_file_info.lua': %s",log_info.fn_related_file_info))
        -- if not log_info.related_files_info then
        --     log(" Couldn't load related_files_info.lua")
        --     return output
        -- end
        -- if not log_info.matching_pargen then
        --     log(" Couldn't match any pargen.parser() for starting filename")
        --     return output
        -- else
        --     if #log_info.matching_pargens > 1 then
        --         log(" matching parsers, pargen name:")
        --         for _, p in ipairs(log_info.matching_pargens) do
        --             log("  '"..p.pargen.name.."'")
        --         end
        --     end
        --     log(" matching pargen parser: '"..log_info.matching_pargen.pargen.name.."'")
        -- end
        --
        -- for rel_ix = 1, nr_keymaps do
        --     if not log_info.related[rel_ix] then
        --         log(" no related pargens for relations index: "..rel_ix)
        --         goto continue
        --     end
        --     log(" related pargens and generated filenames for given relations_index "..rel_ix..":")
        --     for _, related in ipairs(log_info.related[rel_ix]) do
        --         for _, fn_existing in ipairs(related.filenames.existing) do
        --             -- log(string.format("  pargen name '%s': %s (existing)", related.pargen.name, fn_existing))
        --             log(string.format("  related pargen (generator) name: '%s'", related.pargen.name))
        --             log(string.format("    related generated filename: '%s'", fn_existing))
        --             log(string.format("    related generated filename exists:  %s", true))
        --         end
        --         for _, fn_non_existing in ipairs(related.filenames.non_existing) do
        --             -- log(string.format("  pargen name '%s': %s (non_existing)", related.pargen.name, fn_non_existing))
        --             log(string.format("  related pargen (generator) name: '%s'", related.pargen.name))
        --             log(string.format("    related generated filename: '%s'", fn_non_existing))
        --             log(string.format("    related generated filename exists:  %s", false))
        --         end
        --     end
        --
        --     ::continue::
        -- end
        -- return output
    end
    return log_info
end

function M.info_log_buf(nr_keymaps)
    local current_buffer_handle = 0
    return M.info_log(vim.api.nvim_buf_get_name(current_buffer_handle), nr_keymaps)
end

return M
