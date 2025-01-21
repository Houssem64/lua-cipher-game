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
        history = {"Welcome to Terminal v1.1"},
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

    -- Enhanced commands
    if parts[1] == "clear" then
        self.history = {"Terminal cleared"}
    elseif parts[1] == "whoami" then
        table.insert(self.history, "kali")
    elseif parts[1] == "pwd" then
        table.insert(self.history, FileSystem.current_path)
    elseif parts[1] == "ls" then
        local files = FileSystem:listFiles(FileSystem.current_path)
        if #files > 0 then
            table.insert(self.history, table.concat(files, "  "))
        else
            table.insert(self.history, "No files found")
        end
    elseif parts[1] == "cd" then
        if parts[2] then
            local newPath = FileSystem:changePath(parts[2])
            if newPath then
                FileSystem.current_path = newPath
            else
                table.insert(self.history, "cd: " .. parts[2] .. ": No such file or directory")
            end
        else
            FileSystem.current_path = "/home/kali"
        end
    elseif parts[1] == "mkdir" then
        if parts[2] then
            if FileSystem:createDirectory(parts[2]) then
                table.insert(self.history, "Directory created: " .. parts[2])
            else
                table.insert(self.history, "mkdir: Cannot create directory '" .. parts[2] .. "': File exists")
            end
        else
            table.insert(self.history, "mkdir: missing operand")
        end
    elseif parts[1] == "touch" then
        if parts[2] then
            if FileSystem:createFile(parts[2]) then
                table.insert(self.history, "File created: " .. parts[2])
            else
                table.insert(self.history, "touch: Cannot create file '" .. parts[2] .. "': File exists")
            end
        else
            table.insert(self.history, "touch: missing file operand")
        end
    elseif parts[1] == "rm" then
        if parts[2] then
            if FileSystem:removeFile(parts[2]) then
                table.insert(self.history, "Removed: " .. parts[2])
            else
                table.insert(self.history, "rm: cannot remove '" .. parts[2] .. "': No such file or directory")
            end
        else
            table.insert(self.history, "rm: missing operand")
        end
    elseif parts[1] == "echo" then
        table.insert(self.history, table.concat(parts, " ", 2))
    elseif parts[1] == "help" then
        table.insert(self.history, "Available commands:")
        table.insert(self.history, "  clear    - Clear terminal")
        table.insert(self.history, "  whoami   - Show current user")
        table.insert(self.history, "  pwd      - Show current directory")
        table.insert(self.history, "  ls       - List files")
        table.insert(self.history, "  cd       - Change directory")
        table.insert(self.history, "  mkdir    - Create a new directory")
        table.insert(self.history, "  touch    - Create a new file")
        table.insert(self.history, "  rm       - Remove a file")
        table.insert(self.history, "  echo     - Display a line of text")
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

local default_font = love.graphics.getFont()

function Terminal:draw(x, y, width, height)
    -- Terminal background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw terminal text
    love.graphics.setColor(0, 1, 0)  -- Green text
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 24)  -- Adjusted font size for 1080p
    font:setFilter("nearest", "nearest")  -- Set filter to nearest

    love.graphics.setFont(font)
    
    local lineHeight = font:getHeight() * 1.2  -- Add some line spacing
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
    local startLine = math.max(1, #visibleLines - math.floor((height - 20) / lineHeight) + 1)
    for i = startLine, #visibleLines do
        local lineY = y + ((i - startLine) * lineHeight) + 10  -- Add top padding
        if lineY + lineHeight > y + height - 10 then break end  -- Add bottom padding
        love.graphics.print(visibleLines[i], x + 20, lineY)  -- Increased left padding
    end
    
    -- Draw cursor
    if self.cursorBlink and visibleLines[#visibleLines] then
        local cursorX = x + 20 + font:getWidth(currentText)
        local cursorY = y + ((#visibleLines - startLine) * lineHeight) + 10
        love.graphics.rectangle("fill", cursorX, cursorY, 2, lineHeight - 2)  -- Thinner cursor
    end
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
    love.graphics.setFont(default_font)
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