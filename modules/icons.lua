local Icons = {}

function Icons:new()
    local obj = {
        icons = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Icons:load()
    -- Create icons using graphics primitives
    self.icons = {
        terminal = self:createTerminalIcon(),
        files = self:createFilesIcon(),
        email = self:createEmailIcon(),
        text_editor = self:createTextEditorIcon()
    }
end

function Icons:createTerminalIcon()
    local canvas = love.graphics.newCanvas(32, 32)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw terminal icon
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", 4, 4, 24, 24)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 6, 6, 20, 20)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print(">_", 8, 10)
    love.graphics.setCanvas()
    return canvas
end

function Icons:createFilesIcon()
    local canvas = love.graphics.newCanvas(32, 32)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw folder icon
    love.graphics.setColor(0.8, 0.6, 0.2)
    love.graphics.rectangle("fill", 4, 8, 24, 18)
    love.graphics.rectangle("fill", 4, 6, 12, 4)
    love.graphics.setCanvas()
    return canvas
end

function Icons:createEmailIcon()
    local canvas = love.graphics.newCanvas(32, 32)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw envelope icon
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.polygon("fill", 4, 8, 28, 8, 28, 24, 4, 24)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.polygon("fill", 4, 8, 16, 16, 28, 8)
    love.graphics.setCanvas()
    return canvas
end

function Icons:createTextEditorIcon()
    local canvas = love.graphics.newCanvas(32, 32)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw text editor icon
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", 4, 4, 24, 24)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 8, 8, 16, 2)
    love.graphics.rectangle("fill", 8, 12, 16, 2)
    love.graphics.rectangle("fill", 8, 16, 16, 2)
    love.graphics.setCanvas()
    return canvas
end

function Icons:get(name)
    return self.icons[name]
end

return Icons 