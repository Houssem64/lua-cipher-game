local Terminal = {}

function Terminal:new()
    local obj = {
        history = {"Welcome to Terminal v1.0", "> "},
        currentLine = "",
        cursorBlink = true,
        blinkTimer = 0
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Terminal:draw(x, y, width, height)
    -- Terminal background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw terminal text
    love.graphics.setColor(0, 1, 0)  -- Green text
    local lineHeight = 20
    for i, line in ipairs(self.history) do
        love.graphics.print(line, x + 10, y + 10 + (i-1) * lineHeight)
    end
    
    -- Draw current line with cursor
    local currentY = y + 10 + (#self.history * lineHeight)
    love.graphics.print("> " .. self.currentLine, x + 10, currentY)
    
    -- Draw cursor
    if self.cursorBlink then
        local cursorX = x + 10 + love.graphics.getFont():getWidth("> " .. self.currentLine)
        love.graphics.rectangle("fill", cursorX, currentY, 8, lineHeight)
    end
end

function Terminal:update(dt)
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= 0.5 then
        self.cursorBlink = not self.cursorBlink
        self.blinkTimer = 0
    end
end

function Terminal:textinput(text)
    self.currentLine = self.currentLine .. text
end

function Terminal:keypressed(key)
    if key == "return" then
        table.insert(self.history, "> " .. self.currentLine)
        -- Here you could add actual command processing
        if self.currentLine == "clear" then
            self.history = {"Terminal cleared", "> "}
        else
            table.insert(self.history, "Command not found: " .. self.currentLine)
        end
        self.currentLine = ""
    elseif key == "backspace" then
        self.currentLine = self.currentLine:sub(1, -2)
    end
end

return Terminal