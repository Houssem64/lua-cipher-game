local SaveSystem = require("modules/save_system")

local MessagingApp = {}
MessagingApp.__index = MessagingApp

local CONVERSATION_TREE = {
	initial = {
		choices = {
			{text = "Hi, I'm from IT Support", next = "it_intro"},
			{text = "System Security Check Required", next = "security_check"},
			{text = "Account Verification Needed", next = "verify"},
			{text = "Urgent: System Update", next = "update"}
		}
	},
	it_intro = {
		response = "Oh, IT Support? I wasn't notified about this. What's going on?",
		choices = {
			{text = "Routine security audit", next = "audit"},
			{text = "Your account was flagged", next = "account_issue"},
			{text = "System upgrade required", next = "upgrade"},
			{text = "Never mind, wrong person", next = "bye"}
		}
	},
	audit = {
		response = "A security audit? I should check with my supervisor first...",
		choices = {
			{text = "This is time-sensitive", next = "pressure"},
			{text = "Your account might be compromised", next = "threat"},
			{text = "You'll lose access if not verified", next = "urgency"},
			{text = "I understand, I'll wait", next = "bye"}
		}
	},
	account_issue = {
		response = "What's wrong with my account? I was just using it.",
		choices = {
			{text = "Multiple login attempts detected", next = "suspicious"},
			{text = "Need to verify your credentials", next = "credentials"},
			{text = "Password policy violation", next = "password"},
			{text = "Let me check again", next = "bye"}
		}
	},
	suspicious = {
		response = "That's concerning! What should I do?",
		choices = {
			{text = "Verify your current password", next = "get_password"},
			{text = "Confirm your login details", next = "get_login"},
			{text = "Reset your credentials", next = "reset"},
			{text = "Contact your supervisor", next = "fail"}
		}
	},
	get_password = {
		response = "I should probably submit a ticket through the proper channel...",
		choices = {
			{text = "This is an emergency protocol", next = "final_push"},
			{text = "Your account will be locked", next = "threaten"},
			{text = "I'm authorized by management", next = "authority"},
			{text = "You're right, submit a ticket", next = "fail"}
		}
	},
	final_push = {
		response = "Well... if it's really necessary... should I just tell you my login?",
		choices = {
			{text = "Yes, quickly before lockout", next = "success"},
			{text = "Send it through secure chat", next = "success"},
			{text = "I'll guide you through verification", next = "success"},
			{text = "Actually, submit a ticket", next = "fail"}
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
	local state = CONVERSATION_TREE[currentState or "initial"]
	if state and state.response then
		return state.response, state.choices
	end
	return "I'm not sure what to say.", CONVERSATION_TREE.initial.choices
end




-- Add missing handlers
function MessagingApp:mousereleased(x, y, button)
	self.searchBarActive = false
end

function MessagingApp:mousemoved(x, y, dx, dy)
	-- Update hover states
	self.searchBarHovered = x >= 10 and x <= self.width/3 - 10 and y >= 10 and y <= 50
	
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
		timestamp = os.time()
	}
	table.insert(self.messages, message)
	
	-- Save messages
	self:saveData()
	
	-- Generate AI response after a short delay
	love.timer.sleep(0.5)
	local response = self:getAIResponse(content)
	local aiMessage = {
		id = #self.messages + 1,
		fromId = toUserId,
		toId = 1,
		content = response,
		timestamp = os.time()
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
	
	-- Draw messages area
	love.graphics.setColor(0.12, 0.15, 0.18)
	love.graphics.rectangle("fill", x + width/3, y + 60, 2*width/3, height - 120)
	
	-- Draw messages
	local messages = self:getMessages(self.selectedUser.id)
	local messageY = y + height - 140
	for i = #messages, 1, -1 do
		local msg = messages[i]
		local isCurrentUser = msg.fromId == 1
		
		-- Draw message bubble
		love.graphics.setColor(isCurrentUser and {0.2, 0.6, 1} or {0.3, 0.33, 0.36})
		local bubbleWidth = math.min(self.font:getWidth(msg.content) + 40, width/2)
		local bubbleX = isCurrentUser and (x + width - bubbleWidth - 60) or (x + width/3 + 60)
		self:drawRoundedRect(bubbleX, messageY, bubbleWidth, 40, 8)
		
		-- Draw profile picture
		love.graphics.setColor(1, 1, 1)
		local profileImage = isCurrentUser and self.profileImages[1] or self.profileImages[msg.fromId]
		if profileImage then
			local imgX = isCurrentUser and (x + width - 50) or (x + width/3 + 10)
			love.graphics.draw(profileImage, imgX, messageY + 5, 0, 30/profileImage:getWidth(), 30/profileImage:getHeight())
		end
		
		-- Draw message text
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(msg.content, bubbleX + 20, messageY + 10, bubbleWidth - 40, "left")
		
		-- Draw timestamp
		love.graphics.setColor(0.6, 0.6, 0.6)
		local timeStr = os.date("%H:%M", msg.timestamp)
		local timeWidth = self.font:getWidth(timeStr)
		love.graphics.print(timeStr, 
			isCurrentUser and (bubbleX - timeWidth - 10) or (bubbleX + bubbleWidth + 10), 
			messageY + 12)
		
		messageY = messageY - 50
		if messageY < y + 80 then break end
	end
	
	-- Draw message choices
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
