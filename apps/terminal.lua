local FileSystem = require("filesystem")

local Terminal = {}

local States = {
    NORMAL = "normal",
    SUDO = "sudo",
    PASSWORD = "password",
    FTP = "ftp"
}

function Terminal:new()
    local obj = {
        history = {"Welcome to Terminal v1.0"},
        currentLine = "",
        cursorBlink = true,
        blinkTimer = 0,
        state = States.NORMAL,
        passwordAttempts = 0,
        maxPasswordAttempts = 3,
        sudoPassword = "kali",
        scrollPosition = 0,
        maxLines = 20,
        currentCommand = nil
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Terminal:getCurrentPrompt()
    if self.state == States.FTP then
        return "ftp> "
    elseif self.state == States.PASSWORD then
        return "[sudo] password for kali: "
    else
        local dir = FileSystem.current_path:match("[^/]+$") or "~"
        return "kali@kali:" .. (dir == "kali" and "~" or dir) .. "$ "
    end
end

function Terminal:handleCommand(command)
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end

    if #parts == 0 then return end

    if parts[1] == "sudo" then
        self.currentCommand = command
        self.state = States.PASSWORD
        return
    end

    -- Basic commands
    if parts[1] == "clear" then
        self.history = {"Terminal cleared"}
    elseif parts[1] == "whoami" then
        table.insert(self.history, "kali")
    elseif parts[1] == "pwd" then
        table.insert(self.history, "/home/kali")
    elseif parts[1] == "ls" then
        table.insert(self.history, "Documents  Downloads  Desktop  Pictures")
    elseif parts[1] == "help" then
        table.insert(self.history, "Available commands:")
        table.insert(self.history, "  clear    - Clear terminal")
        table.insert(self.history, "  whoami   - Show current user")
        table.insert(self.history, "  pwd      - Show current directory")
        table.insert(self.history, "  ls       - List files")
        table.insert(self.history, "  cd       - Change directory")
        table.insert(self.history, "  sudo     - Run command as root")
    else
        table.insert(self.history, "Command not found: " .. parts[1])
    end
end

function Terminal:handlePassword(password)
    if password == self.sudoPassword then
        self.state = States.NORMAL
        self.passwordAttempts = 0
        table.insert(self.history, "")
        self:handleCommand(self.currentCommand)
    else
        self.passwordAttempts = self.passwordAttempts + 1
        if self.passwordAttempts >= self.maxPasswordAttempts then
            table.insert(self.history, "")
            table.insert(self.history, "sudo: " .. self.passwordAttempts .. " incorrect password attempts")
            self.state = States.NORMAL
            self.passwordAttempts = 0
        end
    end
    self.currentLine = ""
end

function Terminal:draw(x, y, width, height)
    -- Terminal background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw terminal text
    love.graphics.setColor(0, 1, 0)  -- Green text
    local lineHeight = 20
    local visibleLines = {}
    
    -- Add history lines
    for _, line in ipairs(self.history) do
        table.insert(visibleLines, line)
    end
    
    -- Add current prompt and line
    local prompt = self:getCurrentPrompt()
    local currentText = prompt .. (self.state == States.PASSWORD and string.rep("*", #self.currentLine) or self.currentLine)
    table.insert(visibleLines, currentText)
    
    -- Draw visible lines with scrolling
    local startLine = math.max(1, #visibleLines - math.floor(height/lineHeight) + 1)
    for i = startLine, #visibleLines do
        local lineY = y + ((i - startLine) * lineHeight)
        if lineY + lineHeight > y + height then break end
        love.graphics.print(visibleLines[i], x + 10, lineY + 5)
    end
    
    -- Draw cursor
    if self.cursorBlink and visibleLines[#visibleLines] then
        local cursorX = x + 10 + love.graphics.getFont():getWidth(currentText)
        local cursorY = y + ((#visibleLines - startLine) * lineHeight) + 5
        love.graphics.rectangle("fill", cursorX, cursorY, 8, lineHeight)
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
    if self.state == States.PASSWORD then
        self.currentLine = self.currentLine .. text
    else
        self.currentLine = self.currentLine .. text
    end
end

function Terminal:keypressed(key)
    if key == "return" then
        if self.state == States.PASSWORD then
            self:handlePassword(self.currentLine)
        else
            table.insert(self.history, self:getCurrentPrompt() .. self.currentLine)
            self:handleCommand(self.currentLine)
            self.currentLine = ""
        end
    elseif key == "backspace" then
        self.currentLine = self.currentLine:sub(1, -2)
    end
end

return Terminal