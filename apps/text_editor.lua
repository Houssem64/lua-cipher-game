local TextEditor = {}

function TextEditor:new()
    local obj = {
        text = "",
        lines = {"Welcome to Text Editor", "Type something..."},
        cursorX = 1,
        cursorY = 1,
        cursorBlink = true,
        blinkTimer = 0,
        scrollY = 0
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function TextEditor:draw(x, y, width, height)
    -- Editor background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw text
    love.graphics.setColor(0, 0, 0)
    local lineHeight = 20
    for i, line in ipairs(self.lines) do
        local yPos = y + 5 + ((i-1) * lineHeight) - self.scrollY
        if yPos >= y and yPos <= y + height then
            love.graphics.print(line, x + 5, yPos)
        end
    end
    
    -- Draw cursor
    if self.cursorBlink then
        local cursorX = x + 5 + love.graphics.getFont():getWidth(self.lines[self.cursorY]:sub(1, self.cursorX - 1))
        local cursorY = y + 5 + ((self.cursorY-1) * lineHeight) - self.scrollY
        love.graphics.rectangle("fill", cursorX, cursorY, 2, lineHeight)
    end
end

function TextEditor:update(dt)
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= 0.5 then
        self.cursorBlink = not self.cursorBlink
        self.blinkTimer = 0
    end
end

function TextEditor:textinput(text)
    local currentLine = self.lines[self.cursorY]
    self.lines[self.cursorY] = currentLine:sub(1, self.cursorX - 1) .. text .. currentLine:sub(self.cursorX)
    self.cursorX = self.cursorX + 1
end

function TextEditor:keypressed(key)
    if key == "return" then
        local currentLine = self.lines[self.cursorY]
        local restOfLine = currentLine:sub(self.cursorX)
        self.lines[self.cursorY] = currentLine:sub(1, self.cursorX - 1)
        table.insert(self.lines, self.cursorY + 1, restOfLine)
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
    elseif key == "backspace" then
        local currentLine = self.lines[self.cursorY]
        if self.cursorX > 1 then
            self.lines[self.cursorY] = currentLine:sub(1, self.cursorX - 2) .. currentLine:sub(self.cursorX)
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            local previousLine = self.lines[self.cursorY - 1]
            self.cursorX = #previousLine + 1
            self.lines[self.cursorY - 1] = previousLine .. currentLine
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
        end
    elseif key == "left" then
        self.cursorX = math.max(1, self.cursorX - 1)
    elseif key == "right" then
        self.cursorX = math.min(#self.lines[self.cursorY] + 1, self.cursorX + 1)
    elseif key == "up" then
        if self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = math.min(self.cursorX, #self.lines[self.cursorY] + 1)
        end
    elseif key == "down" then
        if self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = math.min(self.cursorX, #self.lines[self.cursorY] + 1)
        end
    end
end

return TextEditor