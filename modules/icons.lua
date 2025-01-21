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
local default_font = love.graphics.getFont()
function Icons:createTerminalIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw terminal icon
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", 4, 4, 56, 56)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 8, 8, 48, 48)
    love.graphics.setColor(0.2, 0.8, 0.2)
   
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(">_", 12, 16)
    -- Add a highlight
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", 4, 4, 56, 4)
    love.graphics.setCanvas()
    love.graphics.setFont(default_font)
    return canvas
end

function Icons:createFilesIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw folder icon
    love.graphics.setColor(0.9, 0.7, 0.3)
    love.graphics.rectangle("fill", 4, 16, 56, 40)
    love.graphics.rectangle("fill", 4, 8, 28, 12)
    -- Add shading
    love.graphics.setColor(0.8, 0.6, 0.2)
    love.graphics.rectangle("fill", 4, 52, 56, 4)
    love.graphics.rectangle("fill", 56, 16, 4, 36)
    love.graphics.setCanvas()
    return canvas
end

function Icons:createEmailIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw envelope icon
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.polygon("fill", 4, 12, 60, 12, 60, 52, 4, 52)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.polygon("fill", 4, 12, 32, 32, 60, 12)
    -- Add details
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.line(4, 52, 32, 32, 60, 52)
    love.graphics.setCanvas()
    return canvas
end

function Icons:createTextEditorIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw text editor icon
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", 4, 4, 56, 56)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 12, 12, 40, 4)
    love.graphics.rectangle("fill", 12, 20, 32, 4)
    love.graphics.rectangle("fill", 12, 28, 36, 4)
    love.graphics.rectangle("fill", 12, 36, 28, 4)
    love.graphics.rectangle("fill", 12, 44, 36, 4)
    -- Add a border
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", 4, 4, 56, 56)
    love.graphics.setCanvas()
    return canvas
end

function Icons:get(name)
    return self.icons[name]
end

return Icons