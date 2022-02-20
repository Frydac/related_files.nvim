local Path = {}

-- Note: dirname("C:/dir1") == "C:" (use Path.get_root(filename))
function Path.dirname(filename)
    local new_name = vim.fn.fnamemodify(filename, ":h")
    return new_name
end

function Path.absolute(filename)
    return vim.fn.fnamemodify(filename, ":p")
end

function Path.file_exists(filename)
    local readable = vim.fn.filereadable(filename)
    return readable ~= 0
end

function Path.directory_exists(filename)
    return vim.fn.isdirectory(filename) == 1
end

function Path.exists(filename)
    return vim.loop.fs_stat(filename) ~= nil
end

function Path.mkdir_p(dir)
    if not Path.directory_exists(dir) then
        return vim.fn.mkdir(dir, 'p') ~= 0
    end
end

-- NOTE: jit.os: Contains the target OS name: "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other".
function Path.get_root(filename, os)
    local pattern = nil
    os = os or jit.os
    if os == "Windows" then
        pattern = "^%a:"
    else
        pattern = "^/"
    end
    return string.match(filename, pattern)
end

-- TODO: refactor and test if it actually does something like touch
-- BUG: probably should use vim :w to save the file, then the appropriate events are triggered and e.g. nvimrtree knows about the new file.
function Path.touch(filename)
    local dirname = Path.dirname(filename)
    Path.mkdir_p(dirname)
    vim.cmd('silent e '..filename)
    vim.cmd('silent w '..filename)
    -- if Path.exists(filename) then
    --     local file, err = io.open(filename, "a+")
    --     if not file then
    --         print(err)
    --         return nil
    --     else
    --         file:close()
    --         return true
    --     end
    -- else
    --     local dir = Path.dirname(filename)
    --     local dir_ok = Path.mkdir_p(dir)
    --     if not dir_ok then
    --         print("Couldn't create directory for filename '"..filename.."'")
    --         return nil
    --     end
    --     local file, err = io.open(filename, "w")
    --     if file then
    --         file:close()
    --         return true
    --     else
    --         print("Couldn't create file '"..filename.."':")
    --         print(err)
    --         return nil
    --     end
    -- end
end

return Path
