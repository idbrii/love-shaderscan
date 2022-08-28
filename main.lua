
local ShaderScan = require 'shaderscan'

-- Ensure output appears in console as its printed instead of only after
-- program terminates.
io.stdout:setvbuf('no')


local screen = {
    x = 500,
    y = 500,
    half_x = 500/2,
    half_y = 500/2,
}

local shaders
local ball = {
    pos = {
        x = screen.half_x,
        y = screen.half_y,
    },
    size = {
        x = 150,
        y = 150,
    },
}

function love.load(args)
    love.window.setMode(screen.x, screen.y)
    shaders = ShaderScan()
    shaders:load_shader('splitcolor', 'example/splitcolor.glsl')
end


function love.update(dt)
    shaders:update(dt)
    shaders:safe_send('splitcolor', 'iTime', love.timer.getTime())

    local x,y = ball.pos.x, ball.pos.y
    local speed = 300
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        x = x + speed * dt
    elseif love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        x = x - speed * dt
    end
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        y = y - speed * dt
    elseif love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        y = y + speed * dt
    end
    ball.pos.x, ball.pos.y = x,y
end

function love.draw()
    love.graphics.setShader(shaders.s.splitcolor)
    love.graphics.clear(0.1, 0.1, 0.1, 1)
    love.graphics.setColor(1, 0, 1, 0.75)
    love.graphics.circle('fill', ball.pos.x, ball.pos.y, ball.size.x, ball.size.y)
    love.graphics.setShader() -- clear
end
