-- Hot reload shader code.
--
-- Supports #include directives that use the same path names you'd pass to
-- love.filesystem.newFile (project root relative).
--
-- Modifies shader compile errors to include file and line number in a similar
-- format to love's lua errors.


-- Bare bones class.
local function class()
    local cls = {}
    cls.__index = cls
    setmetatable(cls, {
            __call = function(cls_, ...)
                local obj = setmetatable({}, cls)
                obj:ctor(...)
                return obj
            end
        })
    return cls
end


local ShaderScan = class('shaderscan')

function ShaderScan:ctor()
    self._shaders = {}
    self.s = {}
    self.fails = {}
end

local function lastmodified(filepath)
    local info = love.filesystem.getInfo(filepath, "file")
    if info then
        return info.modtime
    else
        return -1
    end
end

local function _process_shader(filepath, already_included)
    assert(not already_included[filepath], "Circular include: ".. filepath)
    already_included[filepath] = true
    local f = love.filesystem.newFile(filepath)
    local ok, err = f:open('r')
    if not ok then
        print(err, filepath)
        error(err)
        return
    end
    local output = {
        lines = {},
        origin_file = {},
        origin_lnum = {},
    }
    local lnum = 0
    for line in f:lines() do
        lnum = lnum + 1 -- only incremented for f
        local include = line:match('#include "(.*)"')
        if include then
            output.had_includes = true
            if already_included[include] then
                line = "// Already included file: ".. include
            else
                local out_from_incl = _process_shader(include, already_included)
                for i,val in ipairs(out_from_incl.lines) do
                    table.insert(output.lines, val)
                    table.insert(output.origin_file, out_from_incl.origin_file[i])
                    table.insert(output.origin_lnum,  out_from_incl.origin_lnum[i])
                end
                line = "// Included file: ".. include
            end
        end
        table.insert(output.lines, line)
        table.insert(output.origin_file, filepath)
        table.insert(output.origin_lnum, lnum)
    end
    return output
end

local function _unsafe_perform_load(s, modified_time)
    -- always update lastmodified so we don't retry loading bad file.
    s.lastmodified = modified_time
    s.shader_content = _process_shader(s.filepath, {})
    --~ print(table.concat(s.shader_content.lines , "\n"))
    assert(#s.shader_content.lines > 0)
    assert(type(s.shader_content.lines[1]) == "string")
    -- newShader may throw exception
    s.shader = love.graphics.newShader(table.concat(s.shader_content.lines, "\n"))
end

local function _get_fileline(shader_content, lnum)
    local origin_file = shader_content.origin_file[lnum]
    local origin_lnum = shader_content.origin_lnum[lnum]
    return origin_file, origin_lnum
end

function ShaderScan:_safe_perform_load(key, new_modified, on_error_fn)
    local s = self._shaders[key]
    local success,err = pcall(_unsafe_perform_load, s, new_modified)
    if success then
        print("Shader reload success:", key)
        self.s[key] = s.shader
    else
        -- Reformat to match my vim 'errorformat'
        local lnum = err:match("Line (%d+):")
        local line = ""
        if lnum then
            lnum = tonumber(lnum)
            assert(lnum, err)
            line = "\nLine:\n".. s.shader_content.lines[lnum]

            local file = s.filepath
            if s.shader_content.had_includes then
                file, lnum = _get_fileline(s.shader_content, lnum)
            end
            local fileline = ("%s:%i: in '%s'"):format(file, lnum, key)
            err = err:gsub("Line (%d+):", fileline)
        end

        err = ("Loading '%s' failed: %s"):format(key, err)
        if not s.dbg.terse_error_msg then
            err = err .. ("\nFile: %s%s"):format(s.filepath, line)
        end
        if s.dbg.dump_file_on_error then
            print(table.concat(s.shader_content.lines, "\n"))
        end
        on_error_fn(err)
    end
end

---
-- Load a shader file with the given name and filepath. Only supports loading
-- from files.
-- Use the name to access the shader: love.graphics.setShader(shaderscan.s[name])
--
-- debug_options = {
--     -- Output shader file with expanded includes when compile fails.
--     dump_file_on_error = true,
--     -- Omit repeated file name and line text on error.
--     terse_error_msg = true
-- }
function ShaderScan:load_shader(name, filepath, debug_options)
    local s = {
        filepath = filepath,
        lastmodified = lastmodified(filepath),
        dbg = debug_options or {},
    }
    self._shaders[name] = s
    self:_safe_perform_load(name, s.lastmodified, error)
    self.s[name] = s.shader
    return s.shader
end

function ShaderScan:update(dt)
    for key,s in pairs(self._shaders) do
        local new_modified = lastmodified(s.filepath)
        if s.lastmodified ~= new_modified then
            self:_safe_perform_load(key, new_modified, print)
        end
    end
end

-- Normally, you can call send on your own, but safe_send lets you ignore
-- errors from variables that get optimized away.
function ShaderScan:safe_send(shader, var, value)
    self.fails[shader] = self.fails[shader] or {}
    local success, msg = xpcall(function()
        self.s[shader]:send(var, value)
    end, debug.traceback)
    if not success and not self.fails[shader][var] then
        -- Reformat to match my vim 'errorformat'
        local repl = (": in '%s': "):format(shader)
        print(msg:gsub(": ", repl, 1))
    end
    self.fails[shader][var] = not success or nil
end

return ShaderScan
