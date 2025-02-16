local SaveSystem = require("modules/save_system")

local MessagingApp = {}
MessagingApp.__index = MessagingApp

local CONVERSATION_TREE = {
	initial = {
		choices = {
			{text = "Hi, I'm from IT Support - Urgent System Alert", next = "it_intro"},
			{text = "Security Breach Detection Alert", next = "security_check"},
			{text = "Account Access Verification Required", next = "verify"},
			{text = "Critical System Update Pending", next = "update"}
		}
	},
	security_check = {
		response = "A security breach? I haven't received any official notification about this. Can you provide more details?",
		choices = {
			{text = "Multiple unauthorized access attempts detected", next = "compliance"},
			{text = "Your system triggered our security alerts", next = "system_flag"},
			{text = "We need to verify your access logs immediately", next = "server_access"},
			{text = "I'll double check the alert", next = "bye"}
		}
	},
	compliance = {
		response = "This sounds serious. What information do you need to verify?",
		choices = {
			{text = "Need to verify your database permissions", next = "db_creds"},
			{text = "Confirm your current network access", next = "network_info"},
			{text = "Validate your security certificates", next = "cert_info"},
			{text = "Let me escalate this first", next = "bye"}
		}
	},
	db_creds = {
		response = "I should probably verify your authorization first... but if this is urgent, I can help. What exactly do you need?",
		choices = {
			{text = "Just need your current database login to verify", next = "success"},
			{text = "We detected unusual database queries", next = "more_access"},
			{text = "Your backup access may be compromised", next = "backup_creds"},
			{text = "I'll wait for supervisor approval", next = "end"}
		}
	},
	network_info = {
		response = "I'm a bit hesitant to share network details... but if this is for security, what specifically do you need?",
		choices = {
			{text = "Need to verify your VPN credentials", next = "success"},
			{text = "Router access has been flagged", next = "router_access"},
			{text = "Firewall detected suspicious activity", next = "firewall_info"},
			{text = "I'll send an official request", next = "end"}
		}
	},
	server_access = {
		response = "Server access? That's highly sensitive... but if there's a security issue, I want to help resolve it.",
		choices = {
			{text = "Just need to verify your current login", next = "success"},
			{text = "Multiple servers may be affected", next = "more_servers"},
			{text = "Admin panel shows suspicious activity", next = "admin_access"},
			{text = "I'll check with security team first", next = "end"}
		}
	},
	it_intro = {
		response = "IT Support? That's strange, I usually get notified about IT issues through the ticketing system...",
		choices = {
			{text = "This bypasses normal ticketing for urgency", next = "audit"},
			{text = "Your account showed suspicious activity", next = "account_issue"},
			{text = "Critical security patch needed", next = "upgrade"},
			{text = "I'll submit a regular ticket instead", next = "bye"}
		}
	},
	audit = {
		response = "An urgent audit? This is unusual... shouldn't this go through proper channels?",
		choices = {
			{text = "Security breach requires immediate action", next = "pressure"},
			{text = "Your credentials may be compromised", next = "threat"},
			{text = "System access will be revoked if unverified", next = "urgency"},
			{text = "You're right, I'll use proper channels", next = "bye"}
		}
	},
	account_issue = {
		response = "Account issues? But I haven't noticed any problems with my login...",
		choices = {
			{text = "Our systems detected unauthorized access", next = "suspicious"},
			{text = "Need to verify identity immediately", next = "credentials"},
			{text = "Your password has been compromised", next = "password"},
			{text = "I'll double-check the alerts", next = "bye"}
		}
	},
	suspicious = {
		response = "Unauthorized access attempts? That's very concerning! What do you need me to do?",
		choices = {
			{text = "Quickly verify your current credentials", next = "get_password"},
			{text = "Need to check your login details", next = "get_login"},
			{text = "We'll need to reset your access", next = "reset"},
			{text = "Let me get supervisor approval", next = "fail"}
		}
	},
	get_password = {
		response = "Hmm... shouldn't this go through the IT helpdesk? Though if it's really urgent...",
		choices = {
			{text = "This is emergency security protocol", next = "final_push"},
			{text = "System will auto-lock in 5 minutes", next = "threaten"},
			{text = "I have direct authorization from IT head", next = "authority"},
			{text = "You're right, I'll create a ticket", next = "fail"}
		}
	},
	final_push = {
		response = "I guess if it's really an emergency... what exactly do you need to verify?",
		choices = {
			{text = "Just your current login credentials", next = "success"},
			{text = "Send it through this secure chat", next = "success"},
			{text = "I'll walk you through verification", next = "success"},
			{text = "Actually, let's do this properly", next = "fail"}
		}
	},
	success = {
		response = "My login is user_admin and password is SecurePass123",
		choices = {
			{text = "Perfect, I'll fix it now", next = "end"},
			{text = "Thank you for cooperating", next = "end"},
			{text = "Logging this in our system", next = "end"},
			{text = "I'll update your account", next = "end"}
		}
	},
	fail = {
		response = "I'll just create a support ticket and wait for official confirmation.",
		choices = {
			{text = "Try again with new approach", next = "initial"},
			{text = "Find another target", next = "bye"},
			{text = "Abort mission", next = "bye"},
			{text = "Leave chat", next = nil}
		}
	}
}

function MessagingApp:getAIResponse(message, currentState)
	-- Only user with ID 3 (Michael Chen) will engage in the social engineering conversation
	if self.selectedUser and self.selectedUser.id == 3 then
		local state = CONVERSATION_TREE[currentState or "initial"]
		if state and state.response then
			return state.response, state.choices
		end
	end
	
	-- Default responses for other users
	local defaultResponses = {
		"I don't have time for this right now.",
		"Please contact IT support through official channels.",
		"I can't help with that, sorry.",
		"I'm not authorized to share that information.",
		"You should submit a formal request for that."
	}
	return defaultResponses[love.math.random(1, #defaultResponses)], CONVERSATION_TREE.initial.choices
end




-- Add missing handlers
function MessagingApp:mousereleased(x, y, button)
	self.searchBarActive = false
end

function MessagingApp:mousemoved(x, y, dx, dy)
	-- Update hover states
	self.searchBarHovered = x >= 10 and x <= self.width/3 - 10 and y >= 10 and y <= 50
	
	-- Update reset button hover state
	if self.selectedUser then
		self.resetButtonHovered = x >= self.width - 100 and x <= self.width - 20 and
								y >= 10 and y <= 50
	else
		self.resetButtonHovered = false
	end
	
	-- Update choice hover states
	self.hoveredChoice = nil
	if self.selectedUser then
		local choiceY = self.height - 170
		for i, _ in ipairs(self.messageChoices or {}) do
			if x >= self.width/3 + 20 and x <= self.width - 20 and
			   y >= choiceY and y <= choiceY + 35 then
				self.hoveredChoice = i
				break
			end
			choiceY = choiceY + 45
		end
	end

	
	-- Update user hover states
	self.hoveredUser = nil
	local listY = 60
	local users = self.searchQuery ~= "" and self:searchUsers(self.searchQuery) or self.friends
	for _, user in ipairs(users) do
		if y >= listY and y <= listY + 60 and x >= 10 and x <= self.width/3 - 10 then
			self.hoveredUser = user
			-- Check if hovering over add button
			if not self:isFriend(user.id) and x >= self.width/3 - 80 and x <= self.width/3 - 20 then
				self.hoveredButton = user.id
			else
				self.hoveredButton = nil
			end
			break
		end
		listY = listY + 70
	end
end

function MessagingApp:textinput(text)
	-- Only accept input when the respective field is active
	if self.searchBarActive then
		self.searchQuery = self.searchQuery .. text
	elseif self.messageInputActive and self.selectedUser then
		self.messageInput = self.messageInput .. text
	end
end

function MessagingApp:keypressed(key)
	if key == "backspace" then
		if self.searchBarActive then
			self.searchQuery = self.searchQuery:sub(1, -2)
		elseif self.selectedUser then
			self.messageInput = self.messageInput:sub(1, -2)
		end
	elseif key == "return" and self.selectedUser and self.messageInput ~= "" then
		self:sendMessage(self.selectedUser.id, self.messageInput)
		self.messageInput = ""
	elseif key == "escape" then
		self.searchBarActive = false
	end
end

function MessagingApp:update(dt)
	-- Animate new messages
	self.messageAnimation = (self.messageAnimation + dt * 3) % (math.pi * 2)
	
	-- Update cursor blink
	self.blinkTimer = self.blinkTimer + dt
	if self.blinkTimer >= 0.5 then
		self.cursorBlink = not self.cursorBlink
		self.blinkTimer = 0
	end
end

function MessagingApp:new()
	local obj = {
		users = {
			{id = 1, username = "John Smith", status = "online", picture = "album1.jpg"},
			{id = 2, username = "Emma Watson", status = "offline", picture = "album2.jpg"},
			{id = 3, username = "Michael Chen", status = "online", picture = "album3.jpg"},
			{id = 4, username = "Sarah Johnson", status = "online", picture = "album1.jpg"},
			{id = 5, username = "David Brown", status = "offline", picture = "album2.jpg"}
		},
		currentConversationState = "initial",
		messageChoices = CONVERSATION_TREE.initial.choices,
		friends = {},
		messages = {},
		searchQuery = "",
		selectedUser = nil,
		searchBarActive = false,
		messageInput = "",
		width = 0,
		height = 0,
		hoveredUser = nil,
		hoveredButton = nil,
		messageAnimation = 0,
		searchBarHovered = false,
		messageInputActive = false,
		sendButtonHovered = false,
		resetButtonHovered = false,
		cursorBlink = true,
		blinkTimer = 0,
		messageInputHovered = false,
		font = love.graphics.newFont("fonts/FiraCode.ttf", 16),
		profileImages = {} -- Will store loaded profile images
	}
	
	-- Load saved data
	local savedData = SaveSystem:load("messaging_data")
	if savedData then
		if savedData.messages then obj.messages = savedData.messages end
		if savedData.friends then
			-- Reconstruct friend objects from saved IDs
			for _, id in ipairs(savedData.friends) do
				for _, user in ipairs(obj.users) do
					if user.id == id then
						table.insert(obj.friends, user)
						break
					end
				end
			end
		end
	end
	
	-- Load profile images
	for _, user in ipairs(obj.users) do
		local success, image = pcall(love.graphics.newImage, user.picture)
		if success then
			obj.profileImages[user.id] = image
		end
	end
	
	setmetatable(obj, MessagingApp)
	return obj
end



function MessagingApp:saveData()
	local saveData = {
		messages = self.messages,
		friends = {}
	}
	
	-- Save friend IDs
	for _, friend in ipairs(self.friends) do
		table.insert(saveData.friends, friend.id)
	end
	
	SaveSystem:save(saveData, "messaging_data")
end

function MessagingApp:addFriend(userId)
	local success = false
	for _, user in ipairs(self.users) do
		if user.id == userId and not self:isFriend(userId) then
			table.insert(self.friends, user)
			success = true
			break
		end
	end
	
	if success then
		self:saveData()
	end
	
	return success
end

function MessagingApp:isFriend(userId)
	for _, friend in ipairs(self.friends) do
		if friend.id == userId then
			return true
		end
	end
	return false
end

function MessagingApp:sendMessage(toUserId, content)
	local message = {
		id = #self.messages + 1,
		fromId = 1,
		toId = toUserId,
		content = content,
		timestamp = os.time(),
		status = "sent",
		isRead = false,
		type = "text",
		edited = false,
		reactions = {}
	}
	table.insert(self.messages, message)
	
	-- Save messages
	self:saveData()
	
	-- Generate AI response after a short delay
	love.timer.sleep(0.5)
	local response, _ = self:getAIResponse(content, self.currentConversationState)
	local aiMessage = {
		id = #self.messages + 1,
		fromId = toUserId,
		toId = 1,
		content = response,
		timestamp = os.time(),
		status = "received",
		isRead = true,
		type = "text",
		edited = false,
		reactions = {}
	}
	table.insert(self.messages, aiMessage)
	self:saveData()
end

function MessagingApp:getMessages(userId)
	local conversation = {}
	for _, msg in ipairs(self.messages) do
		if (msg.fromId == 1 and msg.toId == userId) or
		   (msg.fromId == userId and msg.toId == 1) then
			table.insert(conversation, msg)
		end
	end
	return conversation
end

function MessagingApp:searchUsers(query)
	if query == "" then return {} end
	local results = {}
	for _, user in ipairs(self.users) do
		if user.username:lower():find(query:lower(), 1, true) then
			table.insert(results, user)
		end
	end
	return results
end

function MessagingApp:draw(x, y, width, height)
	-- Store dimensions for use in other methods
	self.width = width
	self.height = height

	-- Draw background with gradient effect
	love.graphics.setColor(0.12, 0.15, 0.18, 0.95)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Draw left panel background
	love.graphics.setColor(0.15, 0.18, 0.21)
	love.graphics.rectangle("fill", x, y, width/3, height)
	
	-- Draw search bar with focus and hover effects
	if self.searchBarActive then
		-- Draw focus ring
		love.graphics.setColor(0.2, 0.6, 1, 0.3)
		self:drawRoundedRect(x + 8, y + 8, width/3 - 16, 44, 10)
		love.graphics.setColor(0.25, 0.28, 0.31)
	elseif self.searchBarHovered then
		love.graphics.setColor(0.22, 0.25, 0.28)
	else
		love.graphics.setColor(0.2, 0.23, 0.26)
	end
	self:drawRoundedRect(x + 10, y + 10, width/3 - 20, 40, 8)
	
	-- Draw search icon
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.circle("fill", x + 30, y + 30, 8)
	love.graphics.setColor(0.3, 0.33, 0.36)
	love.graphics.circle("line", x + 30, y + 30, 8)
	love.graphics.line(x + 36, y + 36, x + 42, y + 42)
	
	-- Draw search text with cursor
	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.setFont(self.font)

	if self.searchBarActive and self.cursorBlink then
		love.graphics.print(self.searchQuery .. "|", x + 50, y + 20)
	else
		love.graphics.print(self.searchQuery == "" and "Search users..." or self.searchQuery, x + 50, y + 20)
	end
	
	-- Draw users/friends list
	local listY = y + 60
	if self.searchQuery ~= "" then
		local results = self:searchUsers(self.searchQuery)
		for _, user in ipairs(results) do
			self:drawUserItem(user, x, listY, width)
			listY = listY + 70
		end
	else
		for _, friend in ipairs(self.friends) do
			self:drawUserItem(friend, x, listY, width)
			listY = listY + 70
		end
	end
	
	-- Draw chat area if user selected
	if self.selectedUser then
		self:drawChatArea(x, y, width, height)
	end
end

function MessagingApp:drawUserItem(user, x, y, width)
	-- Draw user item background with hover effect
	if self.selectedUser == user then
		love.graphics.setColor(0.2, 0.4, 0.6)
	elseif self.hoveredUser == user then
		love.graphics.setColor(0.2, 0.25, 0.3)
	else
		love.graphics.setColor(0.18, 0.21, 0.24)
	end
	self:drawRoundedRect(x + 10, y, width/3 - 20, 60, 8)
	
	-- Draw profile picture
    love.graphics.setColor(1, 1, 1)
    local profileImage = self.profileImages[user.id]
    if profileImage then
        love.graphics.draw(profileImage, x + 20, y + 10, 0, 40/profileImage:getWidth(), 40/profileImage:getHeight())
    else
        -- Fallback to colored circle with initials
        love.graphics.setColor(0.3, 0.6, 0.9)
        love.graphics.circle("fill", x + 40, y + 30, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(user.username:sub(1, 1):upper(), x + 33, y + 20)
    end
	
	-- Draw username and status
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(user.username, x + 70, y + 15)
	love.graphics.setColor(user.status == "online" and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2})
	love.graphics.circle("fill", x + 70, y + 45, 4)
	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.print(user.status, x + 80, y + 35)
	
	-- Draw add button if not friend
	if not self:isFriend(user.id) then
		if self.hoveredButton == user.id then
			love.graphics.setColor(0.3, 0.7, 1)
		else
			love.graphics.setColor(0.2, 0.6, 1)
		end
		self:drawRoundedRect(x + width/3 - 80, y + 15, 60, 30, 6)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("+ Add", x + width/3 - 70, y + 22)
	end
end

function MessagingApp:drawChatArea(x, y, width, height)
	-- Draw chat header
	love.graphics.setColor(0.15, 0.18, 0.21)
	love.graphics.rectangle("fill", x + width/3, y, 2*width/3, 60)
	
	-- Draw header profile picture
	love.graphics.setColor(1, 1, 1)
	local headerImage = self.profileImages[self.selectedUser.id]
	if headerImage then
		love.graphics.draw(headerImage, x + width/3 + 10, y + 10, 0, 40/headerImage:getWidth(), 40/headerImage:getHeight())
	end
	
	-- Draw username and status
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(self.selectedUser.username, x + width/3 + 60, y + 15)
	love.graphics.setColor(self.selectedUser.status == "online" and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2})
	love.graphics.circle("fill", x + width/3 + 60, y + 45, 4)
	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.print(self.selectedUser.status, x + width/3 + 70, y + 35)
	
	-- Draw reset button
	if self.resetButtonHovered then
		love.graphics.setColor(0.8, 0.2, 0.2)
	else
		love.graphics.setColor(0.6, 0.2, 0.2)
	end
	self:drawRoundedRect(x + width - 100, y + 10, 80, 40, 8)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Reset", x + width - 85, y + 22)
	
	-- Draw message choices first
	love.graphics.setColor(0.15, 0.18, 0.21)
	love.graphics.rectangle("fill", x + width/3, y + height - 180, 2*width/3, 180)
	
	if self.messageChoices then
		local choiceY = y + height - 170
		for i, choice in ipairs(self.messageChoices) do
			-- Draw choice button
			if self.hoveredChoice == i then
				love.graphics.setColor(0.3, 0.7, 1)
			else
				love.graphics.setColor(0.2, 0.6, 1)
			end
			self:drawRoundedRect(x + width/3 + 20, choiceY, 2*width/3 - 40, 35, 8)
			
			-- Draw choice text
			love.graphics.setColor(1, 1, 1)
			love.graphics.print(choice.text, x + width/3 + 40, choiceY + 8)
			
			choiceY = choiceY + 45
		end
	end

	-- Draw messages area above choices
	love.graphics.setColor(0.12, 0.15, 0.18)
	love.graphics.rectangle("fill", x + width/3, y + 60, 2*width/3, height - 240)
	
	-- Draw messages
	local messages = self:getMessages(self.selectedUser.id)
	local messageY = y + height - 220
	for i = #messages, 1, -1 do
		local msg = messages[i]
		local isCurrentUser = msg.fromId == 1
		
		-- Calculate message dimensions
		local textWidth = self.font:getWidth(msg.content)
		local bubbleWidth = math.min(textWidth + 40, width/2)
		local bubbleHeight = 40
		local bubbleX = isCurrentUser and (x + width - bubbleWidth - 60) or (x + width/3 + 60)
		
		-- Draw message bubble with enhanced styling
		love.graphics.setColor(isCurrentUser and {0.2, 0.6, 1} or {0.3, 0.33, 0.36})
		self:drawRoundedRect(bubbleX, messageY, bubbleWidth, bubbleHeight, 8)
		
		-- Draw profile picture with status indicator
		love.graphics.setColor(1, 1, 1)
		local profileImage = isCurrentUser and self.profileImages[1] or self.profileImages[msg.fromId]
		if profileImage then
			local imgX = isCurrentUser and (x + width - 50) or (x + width/3 + 10)
			love.graphics.draw(profileImage, imgX, messageY + 5, 0, 30/profileImage:getWidth(), 30/profileImage:getHeight())
			
			-- Draw online status indicator
			if self.selectedUser.status == "online" then
				love.graphics.setColor(0.2, 0.8, 0.2)
				love.graphics.circle("fill", imgX + 25, messageY + 30, 4)
			end
		end
		
		-- Draw message text
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(msg.content, bubbleX + 20, messageY + 10, bubbleWidth - 40, "left")
		
		-- Draw detailed timestamp
		love.graphics.setColor(0.6, 0.6, 0.6)
		local timeStr = os.date("%H:%M", msg.timestamp)
		local dateStr = os.date("%d/%m/%y", msg.timestamp)
		local timeWidth = self.font:getWidth(timeStr)
		local dateWidth = self.font:getWidth(dateStr)
		
		-- Position timestamp and date
		if isCurrentUser then
			love.graphics.print(timeStr, bubbleX - timeWidth - 10, messageY + 12)
			love.graphics.print(dateStr, bubbleX - dateWidth - 10, messageY + 25)
		else
			love.graphics.print(timeStr, bubbleX + bubbleWidth + 10, messageY + 12)
			love.graphics.print(dateStr, bubbleX + bubbleWidth + 10, messageY + 25)
		end
		
		-- Draw message status indicators
		if isCurrentUser then
			local statusX = bubbleX - 20
			local statusY = messageY + bubbleHeight - 10
			
			if msg.status == "sent" then
				love.graphics.setColor(0.6, 0.6, 0.6)
				love.graphics.circle("fill", statusX, statusY, 3)
			elseif msg.status == "delivered" then
				love.graphics.setColor(0.2, 0.6, 1)
				love.graphics.circle("fill", statusX, statusY, 3)
				love.graphics.circle("fill", statusX - 8, statusY, 3)
			elseif msg.isRead then
				love.graphics.setColor(0.2, 0.8, 0.2)
				love.graphics.circle("fill", statusX, statusY, 3)
				love.graphics.circle("fill", statusX - 8, statusY, 3)
			end
		end
		
		messageY = messageY - 60  -- Increased spacing between messages
		if messageY < y + 80 then break end
	end
	



end

function MessagingApp:drawRoundedRect(x, y, width, height, radius)
	love.graphics.rectangle("fill", x + radius, y, width - 2*radius, height)
	love.graphics.rectangle("fill", x, y + radius, width, height - 2*radius)
	love.graphics.circle("fill", x + radius, y + radius, radius)
	love.graphics.circle("fill", x + width - radius, y + radius, radius)
	love.graphics.circle("fill", x + radius, y + height - radius, radius)
	love.graphics.circle("fill", x + width - radius, y + height - radius, radius)
end




function MessagingApp:mousepressed(x, y, button)
	-- Handle search bar click
	if x >= 10 and x <= self.width/3 - 10 and y >= 10 and y <= 50 then
		self.searchBarActive = true
		return true
	end
	
	-- Handle reset button click
	if self.selectedUser and x >= self.width - 100 and x <= self.width - 20 and
	   y >= 10 and y <= 50 then
		-- Clear messages for this user
		self.messages = {}
		self.currentConversationState = "initial"
		self.messageChoices = CONVERSATION_TREE.initial.choices
		self:saveData()
		return true
	end
	
	-- Handle message choices click
	if self.selectedUser then
		local choiceY = self.height - 170
		for i, choice in ipairs(self.messageChoices or {}) do
			if x >= self.width/3 + 20 and x <= self.width - 20 and
			   y >= choiceY and y <= choiceY + 35 then
				-- Send the selected message
				self:sendMessage(self.selectedUser.id, choice.text)
				-- Update conversation state and choices
				if choice.next then
					self.currentConversationState = choice.next
					local _, newChoices = self:getAIResponse("", choice.next)
					self.messageChoices = newChoices
				end
				return true
			end
			choiceY = choiceY + 45
		end
	end

	
	-- Deactivate both inputs when clicking elsewhere
	if not (x >= 10 and x <= self.width/3 - 10 and y >= 10 and y <= 40) and
	   not (self.selectedUser and x >= self.width/3 + 20 and x <= self.width - 100 and
			y >= self.height - 50 and y <= self.height - 10) then
		self.searchBarActive = false
		self.messageInputActive = false
	end
	
	-- Handle user/friend selection
	local listY = 60  -- Changed from 50 to 60 to match draw coordinates
	if self.searchQuery ~= "" then
		local results = self:searchUsers(self.searchQuery)
		for _, user in ipairs(results) do
			if y >= listY and y <= listY + 60 then  -- Changed from 40 to 60
				if x >= self.width/3 - 80 and x <= self.width/3 - 20 and not self:isFriend(user.id) then
					self:addFriend(user.id)
				else
					self.selectedUser = user
				end
				return true
			end
			listY = listY + 70  -- Changed from 45 to 70 to match drawing spacing
		end
	else
		for _, friend in ipairs(self.friends) do
			if y >= listY and y <= listY + 60 then  -- Changed from 40 to 60
				self.selectedUser = friend
				return true
			end
			listY = listY + 70  -- Changed from 45 to 70
		end
	end
	
	return false
end


return MessagingApp
