local MessagingApp = {}
MessagingApp.__index = MessagingApp




-- Add missing handlers
function MessagingApp:mousereleased(x, y, button)
	self.searchBarActive = false
end

function MessagingApp:mousemoved(x, y, dx, dy)
	-- Handle hover effects if needed
end

function MessagingApp:textinput(text)
	if self.searchBarActive then
		self.searchQuery = self.searchQuery .. text
	elseif self.selectedUser then
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
	-- Add any animation or state updates here if needed
end

function MessagingApp:new()
	local obj = {
		users = {
			{id = 1, username = "user1", status = "online"},
			{id = 2, username = "user2", status = "offline"},
			{id = 3, username = "user3", status = "online"}
		},
		friends = {},
		messages = {},
		searchQuery = "",
		selectedUser = nil,
		searchBarActive = false,
		messageInput = "",
		width = 0,
		height = 0
	}
	setmetatable(obj, MessagingApp)
	return obj
end



function MessagingApp:addFriend(userId)
	for _, user in ipairs(self.users) do
		if user.id == userId and not self:isFriend(userId) then
			table.insert(self.friends, user)
			return true
		end
	end
	return false
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
		fromId = 1, -- Current user ID
		toId = toUserId,
		content = content,
		timestamp = os.time()
	}
	table.insert(self.messages, message)
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

	-- Draw background
	love.graphics.setColor(0, 0, 0, 0.9)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Draw search bar
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", x + 10, y + 10, width/3 - 20, 30)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(self.searchQuery == "" and "Search users..." or self.searchQuery, x + 15, y + 15)
	
	-- Draw users/friends list
	local listY = y + 50
	if self.searchQuery ~= "" then
		local results = self:searchUsers(self.searchQuery)
		for _, user in ipairs(results) do
			self:drawUserItem(user, x, listY, width)
			listY = listY + 45
		end
	else
		for _, friend in ipairs(self.friends) do
			self:drawUserItem(friend, x, listY, width)
			listY = listY + 45
		end
	end
	
	-- Draw chat area if user selected
	if self.selectedUser then
		self:drawChatArea(x, y, width, height)
	end

end

function MessagingApp:drawUserItem(user, x, y, width)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", x + 10, y, width/3 - 20, 40)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(user.username, x + 15, y + 10)
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.print(user.status, x + width/3 - 80, y + 10)
	
	if not self:isFriend(user.id) then
		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.print("+ Add", x + width/3 - 60, y + 10)
	end
end

function MessagingApp:drawChatArea(x, y, width, height)
	love.graphics.setColor(0.15, 0.15, 0.15)
	love.graphics.rectangle("fill", x + width/3 + 10, y + 10, 2*width/3 - 20, height - 20)
	
	-- Draw messages
	local messages = self:getMessages(self.selectedUser.id)
	local messageY = y + height - 70
	for i = #messages, 1, -1 do
		local msg = messages[i]
		love.graphics.setColor(msg.fromId == 1 and {0.2, 0.6, 1} or {0.3, 0.3, 0.3})
		love.graphics.rectangle("fill",
			msg.fromId == 1 and (x + width - 200) or (x + width/3 + 20),
			messageY,
			180,
			30)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(msg.content,
			msg.fromId == 1 and (x + width - 190) or (x + width/3 + 30),
			messageY + 5)
		messageY = messageY - 35
		if messageY < y + 50 then break end
	end
	
	-- Draw message input
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", x + width/3 + 20, y + height - 40, 2*width/3 - 40, 30)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(self.messageInput == "" and "Type a message..." or self.messageInput,
		x + width/3 + 25, y + height - 35)

end




function MessagingApp:mousepressed(x, y, button)
	-- Handle search bar click
	if x >= 10 and x <= self.width/3 - 10 and y >= 10 and y <= 40 then
		self.searchBarActive = true
		return true
	end
	
	-- Handle user/friend selection
	local listY = 50
	if self.searchQuery ~= "" then
		local results = self:searchUsers(self.searchQuery)
		for _, user in ipairs(results) do
			if y >= listY and y <= listY + 40 then
				if x >= self.width/3 - 60 and not self:isFriend(user.id) then
					self:addFriend(user.id)
				else
					self.selectedUser = user
				end
				return true
			end
			listY = listY + 45
		end
	else
		for _, friend in ipairs(self.friends) do
			if y >= listY and y <= listY + 40 then
				self.selectedUser = friend
				return true
			end
			listY = listY + 45
		end
	end
	
	return false
end


return MessagingApp
