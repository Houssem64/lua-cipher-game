local FileSystem = require("filesystem")
local SaveSystem = require("modules/save_system")

local Terminal = {}

local States = {
    NORMAL = "normal",
    SUDO = "sudo",
    PASSWORD = "password",
    FTP = "ftp",
    FTP_PASSWORD = "ftp_password",  -- New state for FTP authentication
    NANO = "nano"  -- New state for nano editor
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
        sudoPassword = "admin",
        scrollPosition = 0,
        maxLines = 20,
        currentCommand = nil,
        ftpConnection = nil,
        -- Track used commands for tutorial
        usedCommands = {},
        SaveSystem = SaveSystem,
        
        -- Nano editor state
        nanoState = {
            content = "",
            filename = nil,
            lines = {},
            cursorY = 1,
            cursorX = 1,
            message = ""
        },
        commandHistory = {}, -- Store only user-entered commands
        commandHistoryIndex = nil -- nil means not browsing
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
        return "[sudo] password for love: "
    else
        local savedCreds = self.SaveSystem:load("user_credentials")
        local username = savedCreds and savedCreds.username or "love"
        
        -- Get the current directory name from the full path
        local displayPath = FileSystem.current_path
        if displayPath == "/home/" .. username then
            displayPath = "~"
        elseif displayPath:find("^/home/" .. username .. "/") then
            displayPath = "~" .. displayPath:sub(#("/home/" .. username) + 1)
        end
        
        -- Format with proper spacing and no colon
        return username .. "@love-Desktop " .. displayPath .. " $ "
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
                elseif currentMission.id == 5 then
                    -- Text Editor Master mission
                    if fullCommand:match("^echo.*>.*notes%.txt") then self:updateMissionProgress(5, 1)
                    elseif fullCommand == "cat notes.txt" then self:updateMissionProgress(5, 2)
                    elseif fullCommand == "nano notes.txt" then self:updateMissionProgress(5, 3)
                    elseif fullCommand:match("^echo.*>.*") then self:updateMissionProgress(5, 6)
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
        local target_path = parts[2] and (FileSystem.current_path .. "/" .. parts[2]) or FileSystem.current_path
        local files = FileSystem:listFiles(target_path)
        
        if files then
            -- Filter out . and .. entries
            local filtered_files = {}
            for _, name in ipairs(files) do
                if name ~= "." and name ~= ".." then
                    table.insert(filtered_files, name)
                end
            end
            
            table.sort(filtered_files)
            -- Format output with proper spacing
            local output = ""
            for _, name in ipairs(filtered_files) do
                output = output .. string.format("%-15s", name)
            end
            if output ~= "" then
                table.insert(self.history, output)
            else
                table.insert(self.history, "")  -- Empty directory
            end
        else
            table.insert(self.history, "")  -- Directory doesn't exist or error
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
            FileSystem.current_path = "/home/love"
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
        local outputFile
        local text = {}
        local i = 2
        while i <= #parts do
            if parts[i] == ">" then
                outputFile = parts[i + 1]
                break
            end
            table.insert(text, parts[i])
            i = i + 1
        end
        
        local content = table.concat(text, " ")
        if outputFile then
            if FileSystem:writeFile(outputFile, content) then
                table.insert(self.history, "File written: " .. outputFile)
            else
                table.insert(self.history, "Error writing to file: " .. outputFile)
            end
        else
            table.insert(self.history, content)
        end
    elseif parts[1] == "nano" then
        if parts[2] then
            if not FileSystem:readFile(parts[2]) then
                FileSystem:createFile(parts[2])
            end
            self:startNano(parts[2])
        else
            table.insert(self.history, "Usage: nano <filename>")
        end
    elseif parts[1] == "help" then
        table.insert(self.history, "╭─── Terminal Command Reference ─────────────────────────────╮")
        table.insert(self.history, "│  System Information:                                       │")
        table.insert(self.history, "│    neofetch  - Display system information and logo         │")
        table.insert(self.history, "│    whoami    - Show current user                           │")
        table.insert(self.history, "│  File System Navigation:                                   │")
        table.insert(self.history, "│    pwd       - Show current working directory              │")
        table.insert(self.history, "│    ls        - List directory contents                     │")
        table.insert(self.history, "│    cd        - Change directory                            │")
        table.insert(self.history, "│  File Operations:                                          │")
        table.insert(self.history, "│    mkdir     - Create a new directory                      │")
        table.insert(self.history, "│    touch     - Create a new empty file                     │")
        table.insert(self.history, "│    rm        - Remove a file                               │")
        table.insert(self.history, "│    cat       - Display file contents                       │")
        table.insert(self.history, "│    grep      - Search for patterns in files                │")
        table.insert(self.history, "│    chmod     - Change file permissions                     │")
        table.insert(self.history, "│    find      - Search for files by pattern                 │")
        table.insert(self.history, "│  Network:                                                  │")
        table.insert(self.history, "│    ftp       - Connect to FTP server                       │")
        table.insert(self.history, "│    ping      - Test network connectivity                   │")
        table.insert(self.history, "│  Text Editors:                                             │")
        table.insert(self.history, "│    nano      - Text editor                                 │")
        table.insert(self.history, "│  Terminal Control:                                         │")
        table.insert(self.history, "│    clear     - Clear terminal screen                       │")
        table.insert(self.history, "│    echo      - Display a line of text                      │")
        table.insert(self.history, "│    sudo      - Execute command as superuser                │")
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

function Terminal:startNano(filename)
    self.state = States.NANO
    self.nanoState.filename = filename
    self.nanoState.content = FileSystem:readFile(filename) or ""
    self.nanoState.lines = {}
    for line in (self.nanoState.content .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(self.nanoState.lines, line)
    end
    if #self.nanoState.lines == 0 then
        table.insert(self.nanoState.lines, "")
    end
    self.nanoState.cursorY = 1
    self.nanoState.cursorX = 1
    self.nanoState.message = "^X Exit | ^O Save | Home/End Navigate | Arrows Move"
end

function Terminal:handleNanoInput(key)
    -- Track nano-related mission progress
    if _G.missionsManager then
        local currentMission = nil
        for _, mission in ipairs(_G.missions.missions) do
            if mission.selected and not mission.completed and mission.id == 5 then
                if (key == "o" or key == "x") and (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
                    if key == "o" then self:updateMissionProgress(5, 4)
                    elseif key == "x" then self:updateMissionProgress(5, 5)
                    end
                elseif key == "up" or key == "down" or key == "left" or key == "right" then
                    self:updateMissionProgress(5, 7)
                end
                break
            end
        end
    end

    if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
        if key == "x" then
            self.state = States.NORMAL
            self.nanoState.message = ""
        elseif key == "o" then
            local content = table.concat(self.nanoState.lines, "\n")
            if FileSystem:writeFile(self.nanoState.filename, content) then
                self.nanoState.message = "Saved " .. self.nanoState.filename
            else
                self.nanoState.message = "Error saving file"
            end
        end
        return
    end

    -- Handle arrow keys and navigation
    if key == "up" then
        if self.nanoState.cursorY > 1 then
            self.nanoState.cursorY = self.nanoState.cursorY - 1
            self.nanoState.cursorX = math.min(self.nanoState.cursorX, #self.nanoState.lines[self.nanoState.cursorY] + 1)
        end
    elseif key == "down" then
        if self.nanoState.cursorY < #self.nanoState.lines then
            self.nanoState.cursorY = self.nanoState.cursorY + 1
            self.nanoState.cursorX = math.min(self.nanoState.cursorX, #self.nanoState.lines[self.nanoState.cursorY] + 1)
        end
    elseif key == "left" then
        if self.nanoState.cursorX > 1 then
            self.nanoState.cursorX = self.nanoState.cursorX - 1
        elseif self.nanoState.cursorY > 1 then
            self.nanoState.cursorY = self.nanoState.cursorY - 1
            self.nanoState.cursorX = #self.nanoState.lines[self.nanoState.cursorY] + 1
        end
    elseif key == "right" then
        local currentLine = self.nanoState.lines[self.nanoState.cursorY]
        if self.nanoState.cursorX <= #currentLine then
            self.nanoState.cursorX = self.nanoState.cursorX + 1
        elseif self.nanoState.cursorY < #self.nanoState.lines then
            self.nanoState.cursorY = self.nanoState.cursorY + 1
            self.nanoState.cursorX = 1
        end
    elseif key == "home" then
        self.nanoState.cursorX = 1
    elseif key == "end" then
        self.nanoState.cursorX = #self.nanoState.lines[self.nanoState.cursorY] + 1
    elseif key == "return" then
        local currentLine = self.nanoState.lines[self.nanoState.cursorY]
        local beforeCursor = currentLine:sub(1, self.nanoState.cursorX - 1)
        local afterCursor = currentLine:sub(self.nanoState.cursorX)
        self.nanoState.lines[self.nanoState.cursorY] = beforeCursor
        table.insert(self.nanoState.lines, self.nanoState.cursorY + 1, afterCursor)
        self.nanoState.cursorY = self.nanoState.cursorY + 1
        self.nanoState.cursorX = 1
    elseif key == "backspace" then
        local currentLine = self.nanoState.lines[self.nanoState.cursorY]
        if self.nanoState.cursorX > 1 then
            self.nanoState.lines[self.nanoState.cursorY] = currentLine:sub(1, self.nanoState.cursorX - 2) .. currentLine:sub(self.nanoState.cursorX)
            self.nanoState.cursorX = self.nanoState.cursorX - 1
        elseif self.nanoState.cursorY > 1 then
            local previousLine = self.nanoState.lines[self.nanoState.cursorY - 1]
            self.nanoState.cursorX = #previousLine + 1
            self.nanoState.lines[self.nanoState.cursorY - 1] = previousLine .. currentLine
            table.remove(self.nanoState.lines, self.nanoState.cursorY)
            self.nanoState.cursorY = self.nanoState.cursorY - 1
        end
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
    if self.state == States.NANO then
        -- Draw nano editor interface with Kali Linux style
        love.graphics.setColor(0.07, 0.07, 0.07, 1) -- Dark gray background
        love.graphics.rectangle("fill", x, y, width, height)
        
        local font = love.graphics.newFont("fonts/FiraCode.ttf", 20)
        love.graphics.setFont(font)
        
        -- Draw status bar with Kali Linux blue-gray color
        love.graphics.setColor(0.15, 0.18, 0.28)
        love.graphics.rectangle("fill", x, y, width, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("File: " .. self.nanoState.filename .. " " .. self.nanoState.message, x + 10, y + 5)
        
        -- Draw command keys footer
        love.graphics.setColor(0.15, 0.18, 0.28)
        love.graphics.rectangle("fill", x, y + height - 30, width, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("^G Get Help  ^O Write Out  ^W Where Is  ^K Cut Text  ^X Exit", x + 10, y + height - 25)
        
        -- Draw text content with Kali Linux cyan/white color
        love.graphics.setColor(0.7, 0.85, 0.9)
        local lineHeight = font:getHeight() * 1.2
        local visibleLines = math.floor((height - 90) / lineHeight)
        local startLine = math.max(1, self.nanoState.cursorY - math.floor(visibleLines/2))
        
        for i = 1, visibleLines do
            local lineNum = startLine + i - 1
            if lineNum <= #self.nanoState.lines then
                love.graphics.print(self.nanoState.lines[lineNum], x + 10, y + 40 + (i-1) * lineHeight)
                if lineNum == self.nanoState.cursorY then
                    -- Draw cursor
                    local cursorX = x + 10 + font:getWidth(self.nanoState.lines[lineNum]:sub(1, self.nanoState.cursorX - 1))
                    if self.cursorBlink then
                        love.graphics.setColor(0.7, 0.85, 0.9, 0.8)
                        love.graphics.rectangle("fill", cursorX, y + 40 + (i-1) * lineHeight, 2, lineHeight)
                    end
                end
            end
        end
        
        love.graphics.setFont(love.graphics.getFont())
        return
    end


    -- Terminal background
    love.graphics.setColor(0.07, 0.07, 0.07, 1)
    love.graphics.rectangle("fill", x, y , width, height )
    -- Terminal font
    local font = love.graphics.newFont("fonts/FiraCode.ttf", 18)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)
    local lineHeight = font:getHeight() * 1.2
    local visibleLines = {}
    for _, line in ipairs(self.history) do
        if type(line) == "string" then
            table.insert(visibleLines, line)
        end
    end
    -- Add current prompt and line
    local prompt = self:getCurrentPrompt()
    local currentText = prompt
    if self.state == States.PASSWORD then
        currentText = currentText .. string.rep("*", #self.currentLine)
    else
        currentText = currentText .. (type(self.currentLine) == "string" and self.currentLine or "")
    end
    table.insert(visibleLines, currentText)
    -- Draw lines with Kali Linux color scheme
    local startLine = math.max(1, #visibleLines - math.floor((height - 50) / lineHeight) + 1)
    for i = startLine, #visibleLines do
        local lineY = y + 35 + ((i - startLine) * lineHeight)
        local line = visibleLines[i]
        self:drawKaliLine(line, font, x + 10, lineY, i == #visibleLines and self.cursorBlink and self.state ~= States.PASSWORD, prompt, self.currentLine)
    end
    love.graphics.setFont(love.graphics.getFont())
end

function Terminal:drawKaliLine(line, font, x, y, showCursor, prompt, currentLine)
    -- Prompt coloring: username@host:path $
    if line:match("@love%-Desktop") or line:match("@kali") then
        local userEnd = line:find("@")
        local pathStart = line:find(" ")
        local pathEnd = line:find(" %$")
        if userEnd and pathStart and pathEnd then
            -- Username in cyan
            love.graphics.setColor(0.2, 0.8, 1)
            love.graphics.print(line:sub(1, userEnd-1), x, y)
            -- @ in white
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("@", x + font:getWidth(line:sub(1, userEnd-1)), y)
            -- Hostname in magenta
            love.graphics.setColor(0.9, 0.3, 0.6)
            local hostWidth = font:getWidth(line:sub(1, userEnd))
            love.graphics.print(line:sub(userEnd+1, pathStart-1), x + hostWidth, y)
            -- Path in blue
            love.graphics.setColor(0.1, 0.6, 0.8)
            local prefixWidth = font:getWidth(line:sub(1, pathStart))
            love.graphics.print(line:sub(pathStart, pathEnd), x + prefixWidth, y)
            -- $ and rest in white
            love.graphics.setColor(0.9, 0.9, 0.9)
            local promptWidth = font:getWidth(line:sub(1, pathEnd))
            love.graphics.print(line:sub(pathEnd+1), x + promptWidth, y)
            -- Cursor
            if showCursor then
                local cursorX = x + font:getWidth(line)
                love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
                love.graphics.rectangle("fill", cursorX, y, 2, font:getHeight())
            end
            return
        end
    end
    -- Password prompts in yellow
    if line:match("^%[sudo%]") or line:match("^Password:") then
        love.graphics.setColor(0.9, 0.8, 0.1)
        love.graphics.print(line, x, y)
        return
    end
    -- FTP prompt in green
    if line:match("^ftp>") then
        love.graphics.setColor(0.2, 0.9, 0.4)
        love.graphics.print(line, x, y)
        return
    end
    -- Error messages in red
    if line:match("^error") or line:match("not found") or line:match("permission denied") then
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.print(line, x, y)
        return
    end
    -- Command output in cyan/white
    if self:isCommandOutputLine(line) then
        love.graphics.setColor(0.8, 0.9, 0.9)
        love.graphics.print(line, x, y)
        return
    end
    -- Default text (input)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(line, x, y)
    if showCursor then
        local cursorX = x + font:getWidth(line)
        love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        love.graphics.rectangle("fill", cursorX, y, 2, font:getHeight())
    end
end

function Terminal:isCommandOutputLine(line)
    return type(line) == "string" and 
           not line:match("@love%-Desktop") and 
           not line:match("^ftp>") and
           not line:match("^Password:") and
           not line:match("^%[sudo%]")
end

function Terminal:update(dt)
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= 0.5 then
        self.cursorBlink = not self.cursorBlink
        self.blinkTimer = 0
    end
end

function Terminal:textinput(text)
    if self.state == States.NANO then
        local currentLine = self.nanoState.lines[self.nanoState.cursorY]
        self.nanoState.lines[self.nanoState.cursorY] = currentLine:sub(1, self.nanoState.cursorX - 1) .. text .. currentLine:sub(self.nanoState.cursorX)
        self.nanoState.cursorX = self.nanoState.cursorX + #text
        return
    elseif self.state == States.PASSWORD then
        self.currentLine = self.currentLine .. text
    else
        self.currentLine = self.currentLine .. text
    end
end

function Terminal:keypressed(key)
    if self.state == States.NANO then
        self:handleNanoInput(key)
        return
    elseif self.state == States.NORMAL then
        if key == "up" then
            if #self.commandHistory > 0 then
                if not self.commandHistoryIndex then
                    self.commandHistoryIndex = #self.commandHistory
                elseif self.commandHistoryIndex > 1 then
                    self.commandHistoryIndex = self.commandHistoryIndex - 1
                end
                self.currentLine = self.commandHistory[self.commandHistoryIndex] or ""
            end
            return
        elseif key == "down" then
            if self.commandHistoryIndex then
                if self.commandHistoryIndex < #self.commandHistory then
                    self.commandHistoryIndex = self.commandHistoryIndex + 1
                    self.currentLine = self.commandHistory[self.commandHistoryIndex]
                else
                    self.commandHistoryIndex = nil
                    self.currentLine = ""
                end
            end
            return
        end
    end

    if key == "return" then
        if self.state == States.PASSWORD then
            self:handlePassword(self.currentLine)
        elseif self.state == States.FTP_PASSWORD then
            self:handleFTPPassword(self.currentLine)
            self.currentLine = ""
        elseif self.state == States.NORMAL then
            table.insert(self.history, self:getCurrentPrompt() .. self.currentLine)
            if self.currentLine ~= "" then
                table.insert(self.commandHistory, self.currentLine)
            end
            self.commandHistoryIndex = nil
            self:handleCommand(self.currentLine)
            self.currentLine = ""
        end
    elseif key == "backspace" then
        self.currentLine = self.currentLine:sub(1, -2)
    end
end


return Terminal