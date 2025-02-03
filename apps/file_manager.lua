local FileSystem = require("filesystem")

local FileManager = {}

function FileManager:handleClipboardOperation(action, file)
    if not file or file.name == ".." then return end
    
    self.clipboard = {
        action = action,
        file = {
            name = file.name,
            path = self.currentPath,
            type = file.type
        }
    }
    
    -- Visual feedback
    self.statusMessage = {
        text = action == "cut" and "Cut: " .. file.name or "Copied: " .. file.name,
        timer = 2,  -- Show for 2 seconds
        color = {0.2, 0.8, 0.2}
    }
end

function FileManager:handlePaste()
    if not self.clipboard.file then return end
    
    local srcPath = self.clipboard.file.path .. "/" .. self.clipboard.file.name
    local destPath = self.currentPath .. "/" .. self.clipboard.file.name
    
    -- Check if destination already exists
    local destDir = FileSystem:getDirectory(self.currentPath)
    if destDir[self.clipboard.file.name] then
        -- Show error message
        self.statusMessage = {
            text = "File already exists: " .. self.clipboard.file.name,
            timer = 2,
            color = {0.8, 0.2, 0.2}
        }
        return
    end
    
    local success = false
    if self.clipboard.action == "cut" then
        success = FileSystem:moveFile(srcPath, destPath)
        if success then
            self.clipboard = { action = nil, file = nil }
        end
    else -- copy
        success = FileSystem:copyFile(srcPath, destPath)
    end
    
    if success then
        self.statusMessage = {
            text = "Operation completed successfully",
            timer = 2,
            color = {0.2, 0.8, 0.2}
        }
    else
        self.statusMessage = {
            text = "Operation failed",
            timer = 2,
            color = {0.8, 0.2, 0.2}
        }
    end
    
    self:refreshFiles()
end

function FileManager:update(dt)
    if self.statusMessage and self.statusMessage.timer > 0 then
        self.statusMessage.timer = self.statusMessage.timer - dt
        if self.statusMessage.timer <= 0 then
            self.statusMessage = nil
        end
    end
end

function FileManager:new()
    local obj = {
        currentPath = "/home/kali",
        files = {},
        selectedFile = nil,
        clipboard = {
            action = nil, -- "cut" or "copy"
            file = nil
        },
        contextMenu = {
            active = false,
            x = 0,
            y = 0,
            options = {},
            selectedFile = nil
        },
        inputDialog = {
            active = false,
            text = "",
            title = "",
            callback = nil
        },
        lastClickTime = 0,
        lastClickFile = nil,
        dragStart = nil,
        dragEnd = nil
    }
    setmetatable(obj, self)
    self.__index = self
    obj:refreshFiles()
    return obj
end

function FileManager:showInputDialog(title, defaultText, callback)
    self.inputDialog = {
        active = true,
        text = defaultText or "",
        title = title,
        callback = callback
    }
end

function FileManager:refreshFiles()
    self.files = {}
    -- Add parent directory option if not at root
    if self.currentPath ~= "/" then
        table.insert(self.files, {name = "..", type = "folder"})
    end
    
    -- Get files from filesystem
    local dirContents = FileSystem:listFiles(self.currentPath)
    
    -- Separate folders and files
    local folders = {}
    local files = {}
    
    for _, name in ipairs(dirContents) do
        local isDir = type(FileSystem:getDirectory(self.currentPath .. "/" .. name)) == "table"
        local item = {
            name = name,
            type = isDir and "folder" or "file"
        }
        if isDir then
            table.insert(folders, item)
        else
            table.insert(files, item)
        end
    end
    
    -- Sort folders and files alphabetically
    local function sortByName(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end
    
    table.sort(folders, sortByName)
    table.sort(files, sortByName)
    
    -- Combine the sorted lists
    for _, folder in ipairs(folders) do
        table.insert(self.files, folder)
    end
    for _, file in ipairs(files) do
        table.insert(self.files, file)
    end
end

function FileManager:getFileIcon(file)
    if file.type == "folder" then
        return "📁"
    else
        local ext = file.name:match("%.([^%.]+)$") or ""
        ext = string.lower(ext)
        
        local icons = {
            txt = "📄",
            lua = "📜",
            png = "🖼️",
            jpg = "🖼️",
            jpeg = "🖼️",
            gif = "🖼️",
            mp3 = "🎵",
            wav = "🎵",
            mp4 = "🎥",
            pdf = "📕",
            doc = "📘",
            docx = "📘",
            xls = "📗",
            xlsx = "📗",
            zip = "📦",
            rar = "📦",
            ["7z"] = "📦",
            exe = "⚙️",
            [""] = "📄"  -- default icon
        }
        
        return icons[ext] or "📄"
    end
end

function FileManager:draw(x, y, width, height)
    -- Draw background
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw current path
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("Path: " .. self.currentPath, x + 10, y + 10)
    
    -- Draw status message if active
    if self.statusMessage and self.statusMessage.timer > 0 then
        love.graphics.setColor(unpack(self.statusMessage.color))
        love.graphics.print(self.statusMessage.text, x + 10, y + height - 45)
    end

    -- Draw keyboard shortcuts help
    love.graphics.setColor(0.5, 0.5, 0.5)
    local shortcuts = "Shortcuts: ↑↓ Navigate | Enter Open | Backspace/← Back | Ctrl+N New File | Ctrl+F New Folder | Del Delete"
    love.graphics.print(shortcuts, x + 10, y + height - 25)
    
    -- Draw files and folders
    local yOffset = 40
    local mouseX, mouseY = love.mouse.getPosition()
    
    for _, file in ipairs(self.files) do
        -- Draw selection highlight
        if self.selectedFile == file.name then
            love.graphics.setColor(0.8, 0.8, 1, 0.3)
            love.graphics.rectangle("fill", x + 5, y + yOffset - 2, width - 10, 24)
        end
        
        -- Draw hover highlight
        if mouseY >= y + yOffset - 2 and mouseY <= y + yOffset + 22 and
           mouseX >= x + 5 and mouseX <= x + width - 5 then
            love.graphics.setColor(0.9, 0.9, 1, 0.2)
            love.graphics.rectangle("fill", x + 5, y + yOffset - 2, width - 10, 24)
        end
        
        -- Draw icon and name
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.print(self:getFileIcon(file), x + 10, y + yOffset)
        
        if file.type == "folder" then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        
        -- Draw file name and details
        local nameWidth = love.graphics.getFont():getWidth(file.name)
        love.graphics.print(file.name, x + 40, y + yOffset)
        
        -- Draw file size or item count for folders
        if file.type == "folder" and file.name ~= ".." then
            local count = #FileSystem:listFiles(self.currentPath .. "/" .. file.name)
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(count .. " items", x + 40 + nameWidth + 20, y + yOffset)
        end
        
        yOffset = yOffset + 25
    end
    
    -- Draw context menu if active
    if self.contextMenu.active then
        love.graphics.setColor(1, 1, 1, 0.95)
        local menuWidth = 200
        local menuHeight = 0
        -- Calculate total height including separators
        for _, option in ipairs(self.contextMenu.options) do
            if option.separator then
                menuHeight = menuHeight + 5
            else
                menuHeight = menuHeight + 25
            end
        end
        
        -- Draw menu background
        love.graphics.rectangle("fill", self.contextMenu.x, self.contextMenu.y, menuWidth, menuHeight)
        
        -- Draw menu border
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", self.contextMenu.x, self.contextMenu.y, menuWidth, menuHeight)
        
        -- Draw menu items
        local currentY = self.contextMenu.y
        for i, option in ipairs(self.contextMenu.options) do
            if option.separator then
                -- Draw separator line
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.line(
                    self.contextMenu.x + 5, currentY + 2,
                    self.contextMenu.x + menuWidth - 5, currentY + 2
                )
                currentY = currentY + 5
            else
                -- Draw hover highlight
                if mouseY >= currentY and mouseY < currentY + 25 and
                   mouseX >= self.contextMenu.x and mouseX <= self.contextMenu.x + menuWidth then
                    love.graphics.setColor(0.9, 0.9, 1)
                    love.graphics.rectangle("fill", self.contextMenu.x, currentY, menuWidth, 25)
                end
                
                -- Draw icon and text
                love.graphics.setColor(0.2, 0.2, 0.2)
                if option.icon then
                    love.graphics.print(option.icon, self.contextMenu.x + 10, currentY + 5)
                    love.graphics.print(option.text, self.contextMenu.x + 35, currentY + 5)
                else
                    love.graphics.print(option.text, self.contextMenu.x + 10, currentY + 5)
                end
                
                currentY = currentY + 25
            end
        end
    end

    
    -- Draw input dialog if active
    if self.inputDialog.active then
        -- Draw dialog background
        love.graphics.setColor(1, 1, 1, 0.95)
        local dialogWidth = 300
        local dialogHeight = 100
        local dialogX = x + (width - dialogWidth) / 2
        local dialogY = y + (height - dialogHeight) / 2
        love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight)
        
        -- Draw border
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight)
        
        -- Draw title and input
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.print(self.inputDialog.title, dialogX + 10, dialogY + 10)
        
        -- Draw input box
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", dialogX + 10, dialogY + 40, dialogWidth - 20, 25)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", dialogX + 10, dialogY + 40, dialogWidth - 20, 25)
        
        -- Draw input text
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.inputDialog.text, dialogX + 15, dialogY + 45)
    end
end

function FileManager:mousepressed(x, y, button)
    if button == 1 then
        self.dragStart = y
        self.dragEnd = y
        -- Close context menu if it's open
        if self.contextMenu.active then
            self.contextMenu.active = false
            return
        end
        
        local yOffset = 40
        for _, file in ipairs(self.files) do
            if y >= yOffset and y <= yOffset + 25 then
                -- Handle double click
                local currentTime = love.timer.getTime()
                if self.lastClickFile == file.name and 
                   currentTime - self.lastClickTime < 0.5 then
                    -- Double click detected
                    if file.type == "folder" then
                        self:changeDirectory(file.name)
                    else
                        -- TODO: Open file in appropriate application
                        print("Opening file: " .. file.name)
                    end
                else
                    -- Single click - just select
                    self.selectedFile = file.name
                end
                
                self.lastClickTime = currentTime
                self.lastClickFile = file.name
                break
            end
            yOffset = yOffset + 25
        end
    elseif button == 2 then -- Right click
        local yOffset = 40
        local clickedFile = nil
        
        -- First check if clicked on a file
        for _, file in ipairs(self.files) do
            if y >= yOffset and y <= yOffset + 25 then
                clickedFile = file
                self.selectedFile = file.name
                break
            end
            yOffset = yOffset + 25
        end
        
        -- Show appropriate context menu
        if clickedFile then
            self:showContextMenu(x, y, clickedFile)
        else
            -- Only show empty space menu if clicked in the file list area
            if y >= 40 and y <= height - 30 then
                self:showContextMenu(x, y, nil)
            end
        end
    end
end

function FileManager:showContextMenu(x, y, file)
    self.contextMenu.active = true
    self.contextMenu.x = x
    self.contextMenu.y = y
    self.contextMenu.selectedFile = file
    self.contextMenu.options = {}
    
    if file then
        if file.name ~= ".." then
            table.insert(self.contextMenu.options, {
                text = "Open",
                icon = "▶️",
                action = function()
                    if file.type == "folder" then
                        self:changeDirectory(file.name)
                    else
                        print("Opening file: " .. file.name)
                    end
                end
            })
            table.insert(self.contextMenu.options, {
                separator = true
            })
            table.insert(self.contextMenu.options, {
                text = "Cut",
                icon = "✂️",
                action = function()
                    self:handleClipboardOperation("cut", file)
                end
            })
            table.insert(self.contextMenu.options, {
                text = "Copy",
                icon = "📋",
                action = function()
                    self:handleClipboardOperation("copy", file)
                end

            })
            table.insert(self.contextMenu.options, {
                separator = true
            })
            table.insert(self.contextMenu.options, {
                text = "Rename",
                icon = "✏️",
                action = function()
                    self:showInputDialog("Rename " .. file.name, file.name, function(newName)
                        if newName and newName ~= "" and newName ~= file.name then
                            if FileSystem:renameFile(file.name, newName) then
                                self.selectedFile = newName
                                self:refreshFiles()
                            end
                        end
                    end)
                end
            })
            table.insert(self.contextMenu.options, {
                text = "Delete",
                icon = "🗑️",
                action = function()
                    FileSystem:removeFile(file.name)
                    self:refreshFiles()
                end
            })
        end
    else
        table.insert(self.contextMenu.options, {
            text = "New File",
            icon = "📄",
            action = function()
                self:showInputDialog("New File Name", "New File.txt", function(name)
                    if name and name ~= "" then
                        FileSystem:createFile(name)
                        self:refreshFiles()
                    end
                end)
            end
        })
        table.insert(self.contextMenu.options, {
            text = "New Folder",
            icon = "📁",
            action = function()
                self:showInputDialog("New Folder Name", "New Folder", function(name)
                    if name and name ~= "" then
                        FileSystem:createDirectory(name)
                        self:refreshFiles()
                    end
                end)
            end
        })
        table.insert(self.contextMenu.options, {
            separator = true
        })
        if self.clipboard.file then
            table.insert(self.contextMenu.options, {
                text = "Paste",
                icon = "📋",
                action = function()
                    self:handlePaste()
                end

            })
            table.insert(self.contextMenu.options, {
                separator = true
            })
        end
        table.insert(self.contextMenu.options, {
            text = "Refresh",
            icon = "🔄",
            action = function()
                self:refreshFiles()
            end
        })
    end
end

function FileManager:textinput(text)
    if self.inputDialog.active then
        self.inputDialog.text = self.inputDialog.text .. text
    end
end

function FileManager:keypressed(key)
    if self.inputDialog.active then
        if key == "return" then
            local callback = self.inputDialog.callback
            local text = self.inputDialog.text
            self.inputDialog.active = false
            if callback then
                callback(text)
            end
        elseif key == "escape" then
            self.inputDialog.active = false
        elseif key == "backspace" then
            self.inputDialog.text = self.inputDialog.text:sub(1, -2)
        end
    else
        -- Global shortcuts
        if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            if key == "n" then
                self:showInputDialog("New File Name", "New File.txt", function(name)
                    if name and name ~= "" then
                        FileSystem:createFile(name)
                        self:refreshFiles()
                    end
                end)
            elseif key == "f" then
                self:showInputDialog("New Folder Name", "New Folder", function(name)
                    if name and name ~= "" then
                        FileSystem:createDirectory(name)
                        self:refreshFiles()
                    end
                end)
            end
        elseif key == "delete" and self.selectedFile and self.selectedFile ~= ".." then
            FileSystem:removeFile(self.selectedFile)
            self:refreshFiles()
        elseif key == "up" or key == "down" then
            -- File navigation
            if #self.files > 0 then
                local currentIndex = 1
                for i, file in ipairs(self.files) do
                    if file.name == self.selectedFile then
                        currentIndex = i
                        break
                    end
                end
                
                if key == "up" then
                    currentIndex = currentIndex - 1
                    if currentIndex < 1 then
                        currentIndex = #self.files
                    end
                else
                    currentIndex = currentIndex + 1
                    if currentIndex > #self.files then
                        currentIndex = 1
                    end
                end
                
                self.selectedFile = self.files[currentIndex].name
            end
        elseif key == "return" and self.selectedFile then
            -- Open folder on enter
            local selectedFile = nil
            for _, file in ipairs(self.files) do
                if file.name == self.selectedFile then
                    selectedFile = file
                    break
                end
            end
            
            if selectedFile and selectedFile.type == "folder" then
                self:changeDirectory(selectedFile.name)
            end
        elseif key == "backspace" or key == "left" then
            -- Go up one directory
            if self.currentPath ~= "/" then
                self:changeDirectory("..")
            end
        end
    end
end

function FileManager:changeDirectory(dir)
    if dir == ".." then
        -- Navigate up one directory
        local lastSlash = self.currentPath:find("/[^/]*$")
        if lastSlash and lastSlash > 1 then
            self.currentPath = self.currentPath:sub(1, lastSlash - 1)
        end
    else
        -- Navigate into the selected directory
        self.currentPath = self.currentPath .. "/" .. dir
    end
    
    self:refreshFiles()
    self.selectedFile = nil
end

function FileManager:mousemoved(x, y)
    if self.dragStart then
        self.dragEnd = y
    end
end

function FileManager:mousereleased(x, y, button)
    if button == 1 then
        self.dragStart = nil
        self.dragEnd = nil
        
        -- Handle drag and drop
        if self.dragStart and self.dragEnd and math.abs(self.dragEnd - self.dragStart) > 5 then
            -- TODO: Implement drag and drop functionality
            print("Drag and drop detected")
        end
    end
    
    if self.contextMenu.active then
        local menuWidth = 200
        local currentY = self.contextMenu.y
        local mouseInMenu = x >= self.contextMenu.x and x <= self.contextMenu.x + menuWidth
        
        for _, option in ipairs(self.contextMenu.options) do
            if not option.separator then
                if mouseInMenu and y >= currentY and y < currentY + 25 then
                    if option.action then
                        option.action()
                    end
                    self.contextMenu.active = false
                    return
                end
                currentY = currentY + 25
            else
                currentY = currentY + 5
            end
        end
        
        -- Close menu if clicked outside
        if not mouseInMenu or y < self.contextMenu.y or y > currentY then
            self.contextMenu.active = false
        end
    end
end

return FileManager