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
    
    -- Check for tutorial mission completion
    if _G.missionsManager then
        -- Check if mission 1 exists and is selected
        if _G.missions then
            local mission = _G.missions:getMissionById(1)
            if mission then
                print("Found mission 1:", mission.text)
                print("Mission selected state:", mission.selected)
                print("Number of missions:", #_G.missions.missions)
                
                -- Check if mission is selected or if it's the only mission
                if (mission.selected or #_G.missions.missions == 1) and not mission.completed then
                    print("Processing command for tutorial mission:", fullCommand)
                    -- Tutorial mission checks
                    if fullCommand == "pwd" and not mission.subtasks[1].completed then
                        self:updateMissionProgress(1, 1)
                        print("Updated pwd task")
                    elseif fullCommand == "neofetch" and not mission.subtasks[2].completed then
                        self:updateMissionProgress(1, 2)
                        print("Updated neofetch task")
                    elseif fullCommand == "whoami" and not mission.subtasks[3].completed then
                        self:updateMissionProgress(1, 3)
                        print("Updated whoami task")
                    elseif fullCommand == "mkdir tutorial" and not mission.subtasks[4].completed then
                        self:updateMissionProgress(1, 4)
                        print("Updated mkdir task")
                    elseif fullCommand == "cd tutorial" and not mission.subtasks[5].completed then
                        self:updateMissionProgress(1, 5)
                        print("Updated cd task")
                    elseif fullCommand == "touch test.txt" and not mission.subtasks[6].completed then
                        self:updateMissionProgress(1, 6)
                        print("Updated touch task")
                    elseif fullCommand == "ls" and not mission.subtasks[7].completed then
                        self:updateMissionProgress(1, 7)
                        print("Updated ls task")
                    elseif fullCommand == "sudo whoami" and not mission.subtasks[8].completed then
                        self:updateMissionProgress(1, 8)
                        print("Updated sudo task")
                    elseif fullCommand == "help" and not mission.subtasks[9].completed then
                        self:updateMissionProgress(1, 9)
                        print("Updated help task")
                    end
                else
                    print("Mission 1 is not selected or already completed")
                end
            else
                print("Mission 1 not found")
            end
        else
            print("_G.missions not found")
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
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  Network:                                                  │")
        table.insert(self.history, "│    ftp       - Connect to FTP server                       │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "│  Terminal Control:                                         │")
        table.insert(self.history, "│    clear     - Clear terminal screen                       │")
        table.insert(self.history, "│    echo      - Display a line of text                      │")
        table.insert(self.history, "│    sudo      - Execute command as superuser                │")
        table.insert(self.history, "│                                                            │")
        table.insert(self.history, "╰────────────────────────────────────────────────────────────╯")
    
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