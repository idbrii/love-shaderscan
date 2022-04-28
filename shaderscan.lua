local class = require "gabe.class"


-- Hot reload shader code.
--
-- Consider using cargo and moving this code into there (so all assets can be
-- hotloaded).
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

local function _unsafe_perform_load(s, modified_time)
    -- always update lastmodified so we don't retry loading bad file.
    s.lastmodified = modified_time
    -- newShader may throw exception
    s.shader = love.graphics.newShader(s.filepath, unpack(s.args))
end

function ShaderScan:load_shader(name, filepath, ...)
    local s = {
        filepath = filepath,
        lastmodified = lastmodified(filepath),
        args = {...},
    }
    self._shaders[name] = s
    _unsafe_perform_load(s, lastmodified(filepath))
    self.s[name] = s.shader
    return s.shader
end

function ShaderScan:update(dt)
    for key,s in pairs(self._shaders) do
        local new_modified = lastmodified(s.filepath)
        if s.lastmodified ~= new_modified then
            local success,err = pcall(_unsafe_perform_load, s, new_modified)
            if success then
                print("Shader reload success:", key)
                self.s[key] = s.shader
            else
                -- Reformat to match my vim 'errorformat'
                local fmt = ("%s(%%1,0) in "):format(s.filepath)
                err = err:gsub("Line (%d+):", fmt)
                print("Shader reload failed:", key, err)
            end
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
