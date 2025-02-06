local FileSystem = require("filesystem")

local Terminal = {}

local States = {
    NORMAL = "normal",
    SUDO = "sudo",
    PASSWORD = "password",
    FTP = "ftp",
    FTP_PASSWORD = "ftp_password"  -- New state for FTP authentication
}
local FTPConnection = {
    host = nil,
    username = nil,
    authenticated = false,
    password = "anonymous"  -- Default FTP password
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
        currentCommand = nil,
        ftpConnection = nil,
        -- Track used commands for tutorial
        usedCommands = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Terminal:getCurrentPrompt()
    if self.state == States.FTP then
        return "ftp> "
    elseif self.state == States.FTP_PASSWORD then
        return "Password: "
    elseif self.state == States.PASSWORD then
        return "[sudo] password for kali: "
    else
        local dir = FileSystem.current_path:match("[^/]+$") or "~"
        return "kali@kali:" .. (dir == "kali" and "~" or dir) .. "$ "
    end
end
function Terminal:showNeofetch()
    local ascii_art = {
        "       _,met$$$$$gg.                    ",
        "    ,g$$$$$$$$$$$$$$$P.                ",
        "  ,g$$P\"\"       \"\"\"Y$$.\".",
        " ,$$P'              `$$$$.             ",
        "',$$P       ,ggs.     `$$b:           ",
        "`d$$'     ,$P\"'   .    $$$            ",
        " $$P      d$'     ,    $$P            ",
        " $$:      $$.   -    ,d$$'            ",
        " $$;      Y$b._   _,d$P'              ",
        " Y$$.    `.`\"Y$$$$P\"'                 ",
        " `$$b      \"-.__                      ",
        "  `Y$$                                ",
        "   `Y$.                               ",
        "     `$$b.                            ",
        "       `Y$$b.                         ",
        "          `\"Y$b._                     ",
        "              `\"\"\"\"                   ",
    }
    local system_info = {
        "OS: Kali GNU/Linux",
        "Kernel: Linux 5.15.0-kali1-amd64",
        "Shell: bash 5.1.4",
        "Terminal: LOVE Terminal v1.1",
        "CPU: Intel i7-10700K @ 3.80GHz",
        "Memory: 16GB RAM",
        "Disk: 512GB SSD"
    }

    local maxLines = math.max(#ascii_art, #system_info)

    -- Create combined lines
    for i = 1, maxLines do
        local line = ""
        if i <= #ascii_art then
            line = ascii_art[i]
        else
            line = string.rep(" ", 40)  -- Padding to align system info
        end
        
        if i <= #system_info then
            line = line .. "    " .. system_info[i]  -- Add spacing between art and info
        end
        
        table.insert(self.history, line)
    end
end

-- FTP related functions
function Terminal:initiateFTPConnection(host, username)
    self.ftpConnection = {
        host = host,
        username = username or "anonymous",
        authenticated = false,
        password = "anonymous"
    }
    self.state = States.FTP_PASSWORD
    table.insert(self.history, "Connecting to " .. host .. "...")
    table.insert(self.history, "Username: " .. (username or "anonymous"))
    table.insert(self.history, "Password: ")
end

function Terminal:handleFTPPassword(password)
    if self.ftpConnection then
        self.ftpConnection.authenticated = true
        self.state = States.FTP
        table.insert(self.history, "")
        table.insert(self.history, "Connected to " .. self.ftpConnection.host)
        table.insert(self.history, "Type 'help' for available commands")
    end
end

function Terminal:handleFTPCommand(command)
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end

    if #parts == 0 then return end

    if parts[1] == "help" then
        table.insert(self.history, "╭─── FTP Command Reference ────────────────────╮")
        table.insert(self.history, "│                                              │")
        table.insert(self.history, "│  Navigation:                                 │")
        table.insert(self.history, "│    ls      - List files and directories      │")
        table.insert(self.history, "│    pwd     - Show current directory          │")
        table.insert(self.history, "│    cd      - Change directory                │")
        table.insert(self.history, "│                                              │")
        table.insert(self.history, "│  File Operations:                            │")
        table.insert(self.history, "│    get     - Download a file                 │")
        table.insert(self.history, "│    put     - Upload a file                   │")
        table.insert(self.history, "│                                              │")
        table.insert(self.history, "│  Connection:                                 │")
        table.insert(self.history, "│    bye     - Close FTP connection            │")
        table.insert(self.history, "│    quit    - Same as 'bye'                   │")
        table.insert(self.history, "│    exit    - Same as 'bye'                   │")
        table.insert(self.history, "│                                              │")
        table.insert(self.history, "│  Usage Examples:                             │")
        table.insert(self.history, "│    get file.txt                              │")
        table.insert(self.history, "│    put local.txt                             │")
        table.insert(self.history, "│    cd /public                                │")
        table.insert(self.history, "│                                              │")
        table.insert(self.history, "╰──────────────────────────────────────────────╯")
    elseif parts[1] == "bye" or parts[1] == "quit" or parts[1] == "exit" then
        self.ftpConnection = nil
        self.state = States.NORMAL
        table.insert(self.history, "FTP connection closed")
    elseif parts[1] == "ls" then
        table.insert(self.history, "drwxr-xr-x  2 ftp ftp  4096 Jan 21 12:34 public")
        table.insert(self.history, "-rw-r--r--  1 ftp ftp  1234 Jan 21 12:34 welcome.txt")
    elseif parts[1] == "get" then
        if parts[2] then
            table.insert(self.history, "Downloading '" .. parts[2] .. "'...")
            table.insert(self.history, "Transfer complete")
        else
            table.insert(self.history, "Usage: get <filename>")
        end
    elseif parts[1] == "put" then
        if parts[2] then
            table.insert(self.history, "Uploading '" .. parts[2] .. "'...")
            table.insert(self.history, "Transfer complete")
        else
            table.insert(self.history, "Usage: put <filename>")
        end
    else
        table.insert(self.history, "Unknown command '" .. parts[1] .. "'")
    end
end



function Terminal:updateMissionProgress(missionId, subtaskIndex)
    if _G.missionsManager then
        -- Let the missions manager handle all the completion logic, including sounds and notifications
        _G.missionsManager:updateProgress(missionId, subtaskIndex, true)
    end
end




function Terminal:handleCommand(command)
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end

    if #parts == 0 then return end

    -- Track command usage for tutorial
    local fullCommand = table.concat(parts, " ")
    self.usedCommands[fullCommand] = true
    
    -- Check for mission completion
    if _G.missionsManager then
        -- Check if missions exist
        if _G.missions then
            -- Get current mission
            local currentMission = nil
            for _, mission in ipairs(_G.missions.missions) do
                if mission.selected and not mission.completed then
                    currentMission = mission
                    break
                end
            end

            if currentMission then
                -- Mission progress tracking based on mission ID
                if currentMission.id == 1 then
                    -- Terminal Basics mission checks
                    if fullCommand == "pwd" then self:updateMissionProgress(1, 1)
                    elseif fullCommand == "neofetch" then self:updateMissionProgress(1, 2)
                    elseif fullCommand == "whoami" then self:updateMissionProgress(1, 3)
                    elseif fullCommand == "mkdir tutorial" then self:updateMissionProgress(1, 4)
                    elseif fullCommand == "cd tutorial" then self:updateMissionProgress(1, 5)
                    elseif fullCommand == "touch test.txt" then self:updateMissionProgress(1, 6)
                    elseif fullCommand == "ls" then self:updateMissionProgress(1, 7)
                    elseif fullCommand == "sudo whoami" then self:updateMissionProgress(1, 8)
                    elseif fullCommand == "help" then self:updateMissionProgress(1, 9)
                    end
                elseif currentMission.id == 2 then
                    -- File Detective mission
                    if fullCommand:match("^echo.*>.*secret%.txt") then self:updateMissionProgress(2, 1)
                    elseif fullCommand == "cat secret.txt" then self:updateMissionProgress(2, 2)
                    elseif fullCommand == "touch data.txt" then self:updateMissionProgress(2, 3)
                    elseif fullCommand:match("^grep.*") then self:updateMissionProgress(2, 4)
                    elseif fullCommand:match("^find.*") then self:updateMissionProgress(2, 5)
                    elseif fullCommand:match("^chmod.*") then self:updateMissionProgress(2, 6)
                    end
                elseif currentMission.id == 3 then
                    -- Network Navigator mission
                    if fullCommand == "ping localhost" then self:updateMissionProgress(3, 1)
                    elseif fullCommand:match("^ftp.*") and self.state == States.FTP then self:updateMissionProgress(3, 2)
                    elseif fullCommand == "get" and self.state == States.FTP then self:updateMissionProgress(3, 3)
                    elseif fullCommand == "put" and self.state == States.FTP then self:updateMissionProgress(3, 4)
                    elseif fullCommand == "ls" and self.state == States.FTP then self:updateMissionProgress(3, 5)
                    elseif (fullCommand == "bye" or fullCommand == "quit" or fullCommand == "exit") and self.state == States.FTP then 
                        self:updateMissionProgress(3, 6)
                    end
                elseif currentMission.id == 4 then
                    -- System Administrator mission
                    if fullCommand:match("^sudo.*") then self:updateMissionProgress(4, 1)
                    elseif fullCommand:match("^mkdir.*") and parts[2]:match("^%d+$") then self:updateMissionProgress(4, 2)
                    elseif fullCommand:match("^chmod.*") then self:updateMissionProgress(4, 3)
                    elseif fullCommand == "neofetch" then self:updateMissionProgress(4, 4)
                    end
                end
            end
        end
    end




    if self.state == States.FTP then
        self:handleFTPCommand(command)
        return
    end

    if parts[1] == "sudo" then
        self.currentCommand = command
        self.state = States.PASSWORD
        return
    end
    if parts[1] == "neofetch" then
        self:showNeofetch()
        return
    end
    if parts[1] == "ftp" then
        if parts[2] then
            self:initiateFTPConnection(parts[2], parts[3])
        else
            table.insert(self.history, "Usage: ftp <host> [username]")
        end
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
        table.insert(self.history, "╭─── Terminal Command Reference ─────────────────────────────╮")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  System Information:                                       │")
        table.insert(self.history, "│    neofetch  - Display system information and logo         │")
        table.insert(self.history, "│    whoami    - Show current user                           │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  File System Navigation:                                   │")
        table.insert(self.history, "│    pwd       - Show current working directory              │")
        table.insert(self.history, "│    ls        - List directory contents                     │")
        table.insert(self.history, "│    cd        - Change directory                            │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  File Operations:                                          │")
        table.insert(self.history, "│    mkdir     - Create a new directory                      │")
        table.insert(self.history, "│    touch     - Create a new empty file                     │")
        table.insert(self.history, "│    rm        - Remove a file                               │")
        table.insert(self.history, "│    cat       - Display file contents                       │")
        table.insert(self.history, "│    grep      - Search for patterns in files                │")
        table.insert(self.history, "│    chmod     - Change file permissions                     │")
        table.insert(self.history, "│    find      - Search for files by pattern                 │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  Network:                                                  │")
        table.insert(self.history, "│    ftp       - Connect to FTP server                       │")
        table.insert(self.history, "│    ping      - Test network connectivity                   │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  Terminal Control:                                         │")
        table.insert(self.history, "│    clear     - Clear terminal screen                       │")
        table.insert(self.history, "│    echo      - Display a line of text                      │")
        table.insert(self.history, "│    sudo      - Execute command as superuser                │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "╰────────────────────────────────────────────────────────────╯")
    
    elseif parts[1] == "ping" then
        if parts[2] then
            table.insert(self.history, "PING " .. parts[2] .. " (127.0.0.1) 56(84) bytes of data.")
            table.insert(self.history, "64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.035 ms")
            table.insert(self.history, "64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.041 ms")
        else
            table.insert(self.history, "Usage: ping <hostname>")
        end
    elseif parts[1] == "cat" then
        if parts[2] then
            local content = FileSystem:readFile(parts[2])
            if content then
                table.insert(self.history, content)
            else
                table.insert(self.history, "cat: " .. parts[2] .. ": No such file")
            end
        else
            table.insert(self.history, "Usage: cat <filename>")
        end
    elseif parts[1] == "grep" then
        if parts[2] and parts[3] then
            local content = FileSystem:readFile(parts[3])
            if content then
                for line in content:gmatch("[^\r\n]+") do
                    if line:match(parts[2]) then
                        table.insert(self.history, line)
                    end
                end
            else
                table.insert(self.history, "grep: " .. parts[3] .. ": No such file")
            end
        else
            table.insert(self.history, "Usage: grep <pattern> <filename>")
        end
    elseif parts[1] == "chmod" then
        if parts[2] and parts[3] then
            table.insert(self.history, "Changed permissions for " .. parts[3])
        else
            table.insert(self.history, "Usage: chmod <permissions> <filename>")
        end
    elseif parts[1] == "find" then
        if parts[2] then
            local files = FileSystem:findFiles(parts[2])
            if #files > 0 then
                for _, file in ipairs(files) do
                    table.insert(self.history, file)
                end
            else
                table.insert(self.history, "No files found")
            end
        else
            table.insert(self.history, "Usage: find <pattern>")
        end
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
    -- Draw terminal background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw terminal text
    love.graphics.setColor(0, 1, 0)  -- Green text
    local default_font = love.graphics.getFont()
    
    -- Use a monospace font that properly supports UTF-8
    local font = love.graphics.newFont("fonts/FiraCode.ttf", 24)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
    
    local lineHeight = font:getHeight() * 1.2
    local visibleLines = {}
    
    -- Safely process history lines
    for _, line in ipairs(self.history) do
        -- Ensure the line is a valid string
        if type(line) == "string" then
            table.insert(visibleLines, line)
        end
    end
    
    -- Add current prompt and line with proper UTF-8 handling
    local prompt = self:getCurrentPrompt()
    local currentText = prompt
    if self.state == States.PASSWORD then
        currentText = currentText .. string.rep("*", #self.currentLine)
    else
        -- Ensure currentLine is a valid string
        currentText = currentText .. (type(self.currentLine) == "string" and self.currentLine or "")
    end
    table.insert(visibleLines, currentText)
    
    -- Draw visible lines with scrolling
    local startLine = math.max(1, #visibleLines - math.floor((height - 20) / lineHeight) + 1)
    for i = startLine, #visibleLines do
        local lineY = y + ((i - startLine) * lineHeight) + 10
        -- Safe print with error handling
        pcall(love.graphics.print, visibleLines[i], x + 10, lineY)
    end
    
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
        elseif self.state == States.FTP_PASSWORD then
            self:handleFTPPassword(self.currentLine)
            self.currentLine = ""
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