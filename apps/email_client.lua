local SaveSystem = require("modules/save_system")

local EmailClient = {}

local EmailStates = {
    INBOX = "inbox",
    COMPOSE = "compose",
    READING = "reading"
}

function EmailClient:new()
    local obj = {
        state = EmailStates.INBOX,
        emails = {
            inbox = {},
            sent = {},
            trash = {},
            drafts = {}
        },
        selectedEmail = nil,
        composeData = {
            to = "",
            subject = "",
            body = "",
            cursorPos = 1,
            activeField = "to"
        },
        scrollPosition = 0,
        maxEmailsVisible = 10,
        sidebarWidth = 250,
        width = 0,
        height = 0,
        currentFolder = "inbox"
    }
    setmetatable(obj, self)
    self.__index = self
    
    obj:loadEmails()
    if not obj.emails.inbox then obj.emails.inbox = {} end
    if not obj.emails.sent then obj.emails.sent = {} end
    if not obj.emails.trash then obj.emails.trash = {} end
    if not obj.emails.drafts then obj.emails.drafts = {} end
    
    if #obj.emails.inbox == 0 then
        obj:addTestEmails()
    end
    return obj
end

function EmailClient:addEmail(email)
    if not self.emails then
        self.emails = {
            inbox = {},
            sent = {},
            trash = {},
            drafts = {}
        }
    end
    
    email.id = #self.emails.inbox + 1
    email.timestamp = email.timestamp or os.time()
    email.read = false
    table.insert(self.emails.inbox, 1, email)
    self:saveEmails()
end

function EmailClient:saveEmails()
    local saveData = {
        inbox = self.emails.inbox,
        sent = self.emails.sent,
        trash = self.emails.trash,
        drafts = self.emails.drafts
    }
    SaveSystem:save(saveData, "emails")
end

function EmailClient:loadEmails()
    local data = SaveSystem:load("emails")
    if data then
        self.emails = {
            inbox = data.inbox or {},
            sent = data.sent or {},
            trash = data.trash or {},
            drafts = data.drafts or {}
        }
    else
        self.emails = {
            inbox = {},
            sent = {},
            trash = {},
            drafts = {}
        }
        self:addEmail({
            from = "admin@system.local",
            subject = "Welcome to your email client",
            body = "Welcome to your new email client!\n\nThis is your first email.",
            timestamp = os.time()
        })
    end
end

function EmailClient:draw(x, y, width, height)
    -- Store dimensions for use in other methods
    self.width = width
    self.height = height
    
    -- Main background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw toolbar
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, width, 30)
    
    -- Draw compose/back button
    love.graphics.setColor(0.3, 0.6, 0.9)
    if self.state == EmailStates.COMPOSE then
        -- Draw back button
        love.graphics.rectangle("fill", x + width - 90, y + 5, 80, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Back", x + width - 70, y + 7)
    else
        -- Draw compose button
        love.graphics.rectangle("fill", x + 10, y + 5, 80, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Compose", x + 20, y + 7)
    end
    
    if self.state == EmailStates.COMPOSE then
        self:drawCompose(x, y + 35, width, height - 35)
    else
        -- Draw sidebar
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x, y + 30, self.sidebarWidth, height - 30)
        
        -- Draw email list in sidebar
        self:drawEmailList(x, y + 30, self.sidebarWidth, height - 30)
        
        -- Draw selected email content
        if self.selectedEmail then
            self:drawEmailContent(x + self.sidebarWidth, y + 30, width - self.sidebarWidth, height - 30)
        end
    end
end

function EmailClient:drawEmailList(x, y, width, height)
    -- Draw folder buttons at the top
    love.graphics.setColor(0.9, 0.9, 0.9)
    local folders = {{"Inbox", "inbox"}, {"Sent", "sent"}, {"Trash", "trash"}}
    local buttonWidth = width / #folders
    
    for i, folder in ipairs(folders) do
        if self.currentFolder == folder[2] then
            love.graphics.setColor(0.8, 0.8, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end
        love.graphics.rectangle("fill", x + (i-1)*buttonWidth, y, buttonWidth-1, 25)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.print(folder[1], x + (i-1)*buttonWidth + 10, y + 5)
    end
    
    -- Draw email list
    local lineHeight = 80
    local currentEmails = self.emails[self.currentFolder]
    
    for i = 1 + self.scrollPosition, math.min(#currentEmails, self.scrollPosition + self.maxEmailsVisible) do
        local email = currentEmails[i]
        local yPos = y + 25 + (i - 1 - self.scrollPosition) * lineHeight
        
        -- Draw email preview content
        if i == self.selectedEmail then
            love.graphics.setColor(0.9, 0.95, 1)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.rectangle("fill", x, yPos, width, lineHeight - 1)
        
        love.graphics.setColor(0.2, 0.2, 0.2)
        if not email.read then
            love.graphics.setColor(0, 0, 0.8)
        end
        
        -- Draw from and time
        love.graphics.print(email.from, x + 10, yPos + 5)
        love.graphics.print(os.date("%H:%M", email.timestamp), x + width - 50, yPos + 5)
        
        -- Draw subject
        love.graphics.print(email.subject, x + 10, yPos + 25)
        
        -- Draw preview of body (first few words)
        love.graphics.setColor(0.5, 0.5, 0.5)
        local words = {}
        for word in email.body:gmatch("%S+") do
            table.insert(words, word)
            if #words >= 5 then break end
        end
        local preview = table.concat(words, " ") .. (#words >= 5 and "..." or "")
        love.graphics.print(preview, x + 10, yPos + 45)
    end
end

function EmailClient:drawEmailContent(x, y, width, height)
    local email = self.emails[self.currentFolder][self.selectedEmail]
    if not email then return end
    
    -- Draw content area background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw delete button in top right
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.rectangle("fill", x + width - 40, y + 10, 30, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("×", x + width - 30, y + 15)
    
    -- Draw email header
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("From: " .. email.from, x + 20, y + 20)
    love.graphics.print("Date: " .. os.date("%Y-%m-%d %H:%M", email.timestamp), x + 20, y + 40)
    love.graphics.print("Subject: " .. email.subject, x + 20, y + 60)
    
    -- Draw separator line
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.line(x + 20, y + 90, x + width - 20, y + 90)
    
    -- Draw email body
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.printf(email.body, x + 20, y + 110, width - 40)
end

function EmailClient:drawCompose(x, y, width, height)
    -- Draw compose area background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw input fields
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("To:", x + 20, y + 20)
    love.graphics.print("Subject:", x + 20, y + 60)
    
    -- Draw input boxes
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x + 100, y + 20, width - 120, 25)
    love.graphics.rectangle("fill", x + 100, y + 60, width - 120, 25)
    love.graphics.rectangle("fill", x + 20, y + 100, width - 40, height - 160)
    
    -- Draw text
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.composeData.to, x + 105, y + 23)
    love.graphics.print(self.composeData.subject, x + 105, y + 63)
    love.graphics.printf(self.composeData.body, x + 25, y + 105, width - 50)
    
    -- Draw send button
    love.graphics.setColor(0.3, 0.6, 0.9)
    love.graphics.rectangle("fill", x + width - 100, y + height - 40, 80, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Send", x + width - 80, y + height - 35)
    
    -- Draw cursor
    if self.composeData.activeField then
        local cursorX, cursorY
        if self.composeData.activeField == "to" then
            cursorX = x + 105 + love.graphics.getFont():getWidth(self.composeData.to)
            cursorY = y + 23
        elseif self.composeData.activeField == "subject" then
            cursorX = x + 105 + love.graphics.getFont():getWidth(self.composeData.subject)
            cursorY = y + 63
        else
            cursorX = x + 25 + love.graphics.getFont():getWidth(self.composeData.body)
            cursorY = y + 105
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", cursorX, cursorY, 2, 20)
    end
end

function EmailClient:sendEmail()
    local email = {
        from = "user@local",
        to = self.composeData.to,
        subject = self.composeData.subject,
        body = self.composeData.body,
        timestamp = os.time()
    }
    table.insert(self.emails.sent, 1, email)
    self:saveEmails()
    self.state = EmailStates.INBOX
end

function EmailClient:mousepressed(x, y, button)
    if button == 1 then
        -- Check compose/back button
        if y <= 30 then
            if self.state == EmailStates.COMPOSE then
                if x >= self.width - 90 and x <= self.width - 10 and y >= 5 and y <= 25 then
                    self.state = EmailStates.INBOX
                    return
                end
            else
                if x >= 10 and x <= 90 and y >= 5 and y <= 25 then
                    self.state = EmailStates.COMPOSE
                    self.composeData = {
                        to = "",
                        subject = "",
                        body = "",
                        activeField = "to"
                    }
                    return
                end
            end
        end

        if self.state == EmailStates.COMPOSE then
            -- Check input field clicks and send button
            if y >= 55 and y <= 80 then
                if x >= 100 and x <= self.width - 20 then
                    self.composeData.activeField = "to"
                end
            elseif y >= 95 and y <= 120 then
                if x >= 100 and x <= self.width - 20 then
                    self.composeData.activeField = "subject"
                end
            elseif y >= 135 and y <= self.height - 50 then
                if x >= 20 and x <= self.width - 20 then
                    self.composeData.activeField = "body"
                end
            end
            
            -- Check send button
            if y >= self.height - 40 and x >= self.width - 100 and x <= self.width - 20 then
                self:sendEmail()
                return
            end
        else
            -- Check folder buttons
            if y <= 55 then
                local buttonWidth = self.sidebarWidth / 3
                local folderIndex = math.floor(x / buttonWidth) + 1
                local folders = {"inbox", "sent", "trash"}
                if folders[folderIndex] then
                    self.currentFolder = folders[folderIndex]
                    self.selectedEmail = nil
                    return
                end
            end

            -- Check delete button when viewing email
            if self.selectedEmail then
                if x >= self.width - 40 and x <= self.width - 10 and
                   y >= 40 and y <= 70 then
                    self:deleteEmail()
                    return
                end
            end

            -- Email list clicks
            local relativeY = y - 55  -- Adjusted for folder buttons
            local clickedIndex = math.floor(relativeY / 80) + self.scrollPosition + 1
            
            if x <= self.sidebarWidth and clickedIndex <= #self.emails[self.currentFolder] and clickedIndex > 0 then
                self.selectedEmail = clickedIndex
                self.emails[self.currentFolder][clickedIndex].read = true
                self:saveEmails()
            end
        end
    end
end

function EmailClient:textinput(text)
    if self.state == EmailStates.COMPOSE then
        local field = self.composeData.activeField
        if field then
            self.composeData[field] = self.composeData[field] .. text
        end
    end
end

function EmailClient:keypressed(key)
    if self.state == EmailStates.COMPOSE then
        if key == "backspace" then
            local field = self.composeData.activeField
            if field then
                self.composeData[field] = self.composeData[field]:sub(1, -2)
            end
        elseif key == "tab" then
            if self.composeData.activeField == "to" then
                self.composeData.activeField = "subject"
            elseif self.composeData.activeField == "subject" then
                self.composeData.activeField = "body"
            else
                self.composeData.activeField = "to"
            end
        elseif key == "return" and self.composeData.activeField == "body" then
            self.composeData.body = self.composeData.body .. "\n"
        elseif key == "escape" then
            self.state = EmailStates.INBOX
        end
    elseif key == "escape" then
        self.selectedEmail = nil
    end
end

function EmailClient:wheelmoved(x, y)
    if self.state == EmailStates.INBOX then
        self.scrollPosition = math.max(0, math.min(
            self.scrollPosition - y,
            #self.emails[self.currentFolder] - self.maxEmailsVisible
        ))
    end
end

function EmailClient:addTestEmails()
    self:addEmail({
        from = "system@admin.local",
        subject = "Welcome to your Email Client",
        body = "Welcome to your new email client!\n\nThis is your first email. You can:\n- Read emails\n- Send new emails\n- Delete emails\n\nEnjoy!",
        timestamp = os.time() - 3600 -- 1 hour ago
    })
    
    self:addEmail({
        from = "mission@hacker.local",
        subject = "New Mission Available",
        body = "Agent,\n\nA new hacking mission is available. Your target is a high-security server.\n\nMission details will follow in the next email.\n\nGood luck!",
        timestamp = os.time() - 7200 -- 2 hours ago
    })
    
    self:addEmail({
        from = "tutorial@system.local",
        subject = "Basic Terminal Commands",
        body = "Here are some basic terminal commands you might find useful:\n\n- ls: List files\n- cd: Change directory\n- cat: Read file contents\n- whoami: Display current user\n\nPractice these commands to improve your skills.",
        timestamp = os.time() - 10800 -- 3 hours ago
    })
end

-- Function to add a mission email
function EmailClient:addMissionEmail(mission)
    self:addEmail({
        from = "mission@control.local",
        subject = "Mission: " .. mission.title,
        body = string.format([[
Mission Brief: %s

Objective: %s

Reward: %s

Status: Active
]], mission.title, mission.description, mission.reward),
        timestamp = os.time(),
        missionId = mission.id
    })
end

-- Function to add a story email
function EmailClient:addStoryEmail(title, content)
    self:addEmail({
        from = "story@system.local",
        subject = title,
        body = content,
        timestamp = os.time()
    })
end

function EmailClient:deleteEmail()
    local email = table.remove(self.emails[self.currentFolder], self.selectedEmail)
    if email and self.currentFolder ~= "trash" then
        table.insert(self.emails.trash, 1, email)
    end
    self.selectedEmail = nil
    self:saveEmails()
end


return EmailClient 