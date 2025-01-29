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
        text_editor = self:createTextEditorIcon(),
        music = self:createMusicIcon(),  -- Add the music icon
        browser = self:createBrowserIcon()  -- Add browser icon
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
function Icons:createBrowserIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    
    -- Draw globe background
    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.circle("fill", 32, 32, 28)
    
    -- Draw grid lines (latitude)
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = -2, 2 do
        love.graphics.line(4, 32 + i * 10, 60, 32 + i * 10)
    end
    
    -- Draw grid lines (longitude)
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = -2, 2 do
        local x = 32 + i * 10
        love.graphics.line(x, 4, x, 60)
    end
    
    -- Add highlight
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.circle("fill", 24, 24, 12)
    
    love.graphics.setCanvas()
    return canvas
end

function Icons:createMusicIcon()
    local canvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    -- Draw a music note icon
    love.graphics.setColor(0.6, 0.2, 0.8)  -- Purple color for the music note
    love.graphics.circle("fill", 32, 32, 20)  -- Head of the note
    love.graphics.rectangle("fill", 28, 52, 8, 20)  -- Stem of the note

    -- Add a highlight to the note
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.circle("fill", 32, 32, 18)  -- Highlight on the head
    love.graphics.rectangle("fill", 28, 52, 8, 18)  -- Highlight on the stem

    -- Add a second smaller note for detail
    love.graphics.setColor(0.6, 0.2, 0.8)
    love.graphics.circle("fill", 48, 16, 12)  -- Head of the second note
    love.graphics.rectangle("fill", 46, 28, 4, 12)  -- Stem of the second note

    -- Add a border around the icon
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", 4, 4, 56, 56)

    love.graphics.setCanvas()
    return canvas
end
function Icons:get(name)
    return self.icons[name]
end

return Icons