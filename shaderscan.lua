local class = require "gabe.class"


-- Hot reload shader code.
--
-- Consider using cargo and moving this code into there (so all assets can be
-- hotloaded).
--
-- Supports #include directives that use the same path names you'd pass to
-- love.filesystem.newFile (project root relative).
local ShaderScan = class('shaderscan')

function ShaderScan:init()
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
    local processed_lines = {}
    for line in f:lines() do
        local include = line:match('#include "(.*)"')
        if include then
            if already_included[include] then
                line = "// Already included file: ".. include
            else
                local incl_file = _process_shader(include, already_included)
                for i,val in ipairs(incl_file) do
                    table.insert(processed_lines, val)
                end
                line = "// Included file: ".. include
            end
        end
        table.insert(processed_lines, line)
    end
    return processed_lines
end

local function _unsafe_perform_load(s, modified_time)
    -- always update lastmodified so we don't retry loading bad file.
    s.lastmodified = modified_time
    s.shader_lines = _process_shader(s.filepath, {})
    --~ print(table.concat(s.shader_lines , "\n"))
    -- newShader may throw exception
    s.shader = love.graphics.newShader(table.concat(s.shader_lines , "\n"))
end

function ShaderScan:_safe_perform_load(key, new_modified, on_error_fn)
    local s = self._shaders[key]
    local success,err = pcall(_unsafe_perform_load, s, new_modified)
    if success then
        print("Shader reload success:", key)
        self.s[key] = s.shader
    else
        -- Reformat to match my vim 'errorformat'
        local fmt = ("%s(%%1,0) in "):format(s.filepath)
        err = err:gsub("Line (%d+):", fmt)
        err = ("Loading '%s' failed: %s\nFile was: %s"):format(key, err, s.filepath)
        on_error_fn(err)
    end
end

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
