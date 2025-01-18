local TextEditor = {}
local SaveSystem = require("modules.save_system")  -- Add this line at the beginning

function TextEditor:new()
    local obj = {
        text = "",
        lines = {""},
        cursorX = 1,
        cursorY = 1,
        cursorBlink = true,
        blinkTimer = 0,
        scrollY = 0,
        currentFile = nil,
        showFileDialog = false,
        fileDialogMode = nil, -- "open" or "save"
        fileDialogInput = "",
        fileList = {},  -- List of saved text files
        selectedFileIndex = 1
    }
    setmetatable(obj, self)
    self.__index = self
    obj:refreshFileList()  -- Initialize the file list

    return obj
end
function TextEditor:refreshFileList()
    local savedFiles = SaveSystem:load("text_files") or {}
    self.fileList = {}
    for filename, _ in pairs(savedFiles) do
        table.insert(self.fileList, filename)
    end
    table.sort(self.fileList)
    self.selectedFileIndex = 1  -- Reset the selected index when refreshing
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

    -- Draw file dialog if active
    if self.showFileDialog then
        self:drawFileDialog(x, y, width, height)
    end
end


function TextEditor:drawFileDialog(x, y, width, height)
    -- Draw dialog background
    love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
    love.graphics.rectangle("fill", x + width/4, y + height/4, width/2, height/2)

    -- Draw dialog text
    love.graphics.setColor(0, 0, 0)
    local dialogText = self.fileDialogMode == "open" and "Open File:" or "Save File:"
    love.graphics.print(dialogText, x + width/4 + 10, y + height/4 + 10)

    -- Draw input box
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x + width/4 + 10, y + height/4 + 40, width/2 - 20, 30)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.fileDialogInput, x + width/4 + 15, y + height/4 + 45)

    -- Draw file list (only for open dialog)
    if self.fileDialogMode == "open" then
        for i, file in ipairs(self.fileList) do
            local yPos = y + height/4 + 80 + (i-1) * 20
            if i == self.selectedFileIndex then
                love.graphics.setColor(0.7, 0.7, 1)
                love.graphics.rectangle("fill", x + width/4 + 10, yPos, width/2 - 20, 20)
            end
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(file, x + width/4 + 15, yPos)
        end
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
    if self.showFileDialog then
        self.fileDialogInput = self.fileDialogInput .. text
    else
        local currentLine = self.lines[self.cursorY]
        self.lines[self.cursorY] = currentLine:sub(1, self.cursorX - 1) .. text .. currentLine:sub(self.cursorX)
        self.cursorX = self.cursorX + 1
    end
end

function TextEditor:keypressed(key)
    if self.showFileDialog then
        if key == "return" then
            self:handleFileDialog()
        elseif key == "backspace" then
            self.fileDialogInput = self.fileDialogInput:sub(1, -2)
        elseif key == "escape" then
            self.showFileDialog = false
        elseif self.fileDialogMode == "open" then
            if key == "up" then
                self.selectedFileIndex = math.max(1, self.selectedFileIndex - 1)
            elseif key == "down" then
                self.selectedFileIndex = math.min(#self.fileList, self.selectedFileIndex + 1)
            end
        end
    else
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
        elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            if key == "n" then
                self:newFile()
            elseif key == "o" then
                self:openFile()
            elseif key == "s" then
                self:saveFile()
            end
        end
    end
end

function TextEditor:newFile()
    self.lines = {""}
    self.cursorX = 1
    self.cursorY = 1
    self.currentFile = nil
end

function TextEditor:openFile()
    self.showFileDialog = true
    self.fileDialogMode = "open"
    self.fileDialogInput = ""
    self:refreshFileList()
end

function TextEditor:saveFile()
    if self.currentFile then
        self:writeToFile(self.currentFile)
    else
        self.showFileDialog = true
        self.fileDialogMode = "save"
        self.fileDialogInput = ""
    end
end

function TextEditor:handleFileDialog()
    if self.fileDialogMode == "open" then
        if #self.fileList > 0 then
            self:loadFromFile(self.fileList[self.selectedFileIndex])
        else
            -- If no files in the list, try to load the input as a filename
            self:loadFromFile(self.fileDialogInput)
        end
    elseif self.fileDialogMode == "save" then
        self:writeToFile(self.fileDialogInput)
    end
    self.showFileDialog = false
end
function TextEditor:loadFromFile(filename)
    local savedFiles = SaveSystem:load("text_files") or {}
    local fileContent = savedFiles[filename]
    if fileContent and fileContent.lines then
        self.lines = fileContent.lines
        self.currentFile = filename
        self.cursorX = 1
        self.cursorY = 1
        print("File loaded: " .. filename)
    else
        print("Failed to load file: " .. filename)
    end
end

function TextEditor:writeToFile(filename)
    local savedFiles = SaveSystem:load("text_files") or {}
    savedFiles[filename] = {
        lines = self.lines
    }
    local success = SaveSystem:save(savedFiles, "text_files")
    if success then
        self.currentFile = filename
        print("File saved: " .. self.currentFile)
        self:refreshFileList()  -- Refresh the file list after saving
    else
        print("Failed to save file: " .. filename)
    end
end


return TextEditor