local WebBrowser = {}

function WebBrowser:new()
	local obj = {
		currentUrl = "about:blank",
		searchText = "",
		history = {},
		historyIndex = 1,
		width = 0,
		height = 0,
		activeField = nil,
		searchBarHeight = 40,
		urlBarHeight = 40,
		toolbarHeight = 80,
		isLoading = false,
		loadingProgress = 0,
		buttonWidth = 30,
		defaultProtocol = "https://",
		statusBarHeight = 25,
		statusMessage = "Ready"
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function WebBrowser:draw(x, y, width, height)
	self.width = width
	self.height = height
	
	-- Draw background
	love.graphics.setColor(0.95, 0.95, 0.95)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Draw navigation buttons
	-- Back button
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", x + 10, y + 10, self.buttonWidth, self.urlBarHeight)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("←", x + 20, y + 20)
	
	-- Forward button
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", x + 50, y + 10, self.buttonWidth, self.urlBarHeight)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("→", x + 60, y + 20)
	
	-- Draw URL bar
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x + 90, y + 10, width - 100, self.urlBarHeight)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print(self.currentUrl, x + 100, y + 20)
	
	-- Draw search bar
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x + 10, y + self.urlBarHeight + 10, width - 20, self.searchBarHeight)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("Search:", x + 20, y + self.urlBarHeight + 20)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(self.searchText, x + 100, y + self.urlBarHeight + 20)
	
	-- Draw loading bar if loading
	if self.isLoading then
		love.graphics.setColor(0.3, 0.6, 0.9)
		love.graphics.rectangle("fill", x, y + self.toolbarHeight - 2, width * self.loadingProgress, 2)
	end
	
	-- Draw refresh button
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", x + width - 40, y + 10, self.buttonWidth, self.urlBarHeight)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("⟳", x + width - 30, y + 20)
	
	-- Draw content area (adjusted for status bar)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x, y + self.toolbarHeight, width, height - self.toolbarHeight - self.statusBarHeight)
	
	-- Draw status bar
	love.graphics.setColor(0.9, 0.9, 0.9)
	love.graphics.rectangle("fill", x, height - self.statusBarHeight, width, self.statusBarHeight)
	love.graphics.setColor(0.3, 0.3, 0.3)
	local status = self.isLoading and "Loading... " .. math.floor(self.loadingProgress * 100) .. "%" or self.statusMessage
	love.graphics.print(status, x + 10, height - self.statusBarHeight + 5)
	
	-- Draw navigation buttons with hover effect
	if self.historyIndex > 1 then
		love.graphics.setColor(0.7, 0.7, 0.7)
	else
		love.graphics.setColor(0.85, 0.85, 0.85)
	end
	love.graphics.rectangle("fill", x + 10, y + 10, self.buttonWidth, self.urlBarHeight)
	
	if self.historyIndex < #self.history then
		love.graphics.setColor(0.7, 0.7, 0.7)
	else
		love.graphics.setColor(0.85, 0.85, 0.85)
	end
	love.graphics.rectangle("fill", x + 50, y + 10, self.buttonWidth, self.urlBarHeight)
	
	-- Draw active field indicator
	if self.activeField then
		love.graphics.setColor(0.3, 0.6, 0.9, 0.3)
		if self.activeField == "url" then
			love.graphics.rectangle("fill", x + 90, y + 10, width - 100, self.urlBarHeight)
		else
			love.graphics.rectangle("fill", x + 10, y + self.urlBarHeight + 10, width - 20, self.searchBarHeight)
		end
	end
end

function WebBrowser:mousepressed(x, y, button)
	if button == 1 then
		-- Check refresh button
		if y >= 10 and y <= self.urlBarHeight + 10 and 
		   x >= self.width - 40 and x <= self.width - 10 then
			self:refresh()
			return
		end
		
		-- Check back button
		if y >= 10 and y <= self.urlBarHeight + 10 and x >= 10 and x <= 40 then
			self:navigateBack()
			return
		end
		
		-- Check forward button
		if y >= 10 and y <= self.urlBarHeight + 10 and x >= 50 and x <= 80 then
			self:navigateForward()
			return
		end
		
		-- Check URL bar click
		if y <= self.urlBarHeight + 10 and x >= 90 then
			self.activeField = "url"
		-- Check search bar click
		elseif y <= self.toolbarHeight then
			self.activeField = "search"
		else
			self.activeField = nil
		end
	end
end

function WebBrowser:textinput(text)
	if self.activeField == "url" then
		self.currentUrl = self.currentUrl .. text
	elseif self.activeField == "search" then
		self.searchText = self.searchText .. text
	end
end

function WebBrowser:navigateBack()
	if self.historyIndex > 1 then
		self.historyIndex = self.historyIndex - 1
		self.currentUrl = self.history[self.historyIndex]
		self:startLoading()
	end
end

function WebBrowser:navigateForward()
	if self.historyIndex < #self.history then
		self.historyIndex = self.historyIndex + 1
		self.currentUrl = self.history[self.historyIndex]
		self:startLoading()
	end
end

function WebBrowser:startLoading()
	self.isLoading = true
	self.loadingProgress = 0
	self.statusMessage = "Loading " .. self.currentUrl
end

function WebBrowser:update(dt)
	if self.isLoading then
		self.loadingProgress = self.loadingProgress + dt
		if self.loadingProgress >= 1 then
			self.isLoading = false
			self.loadingProgress = 0
			self.statusMessage = "Done"
		end
	end
end

function WebBrowser:refresh()
	self:startLoading()
end

function WebBrowser:formatUrl(url)
	if url:match("^https?://") then
		return url
	elseif url:match("^%w+%.%w+") then
		return self.defaultProtocol .. url
	else
		return self.defaultProtocol .. "www.google.com/search?q=" .. url
	end
end

function WebBrowser:keypressed(key)
	if key == "backspace" then
		if self.activeField == "url" then
			self.currentUrl = self.currentUrl:sub(1, -2)
		elseif self.activeField == "search" then
			self.searchText = self.searchText:sub(1, -2)
		end
	elseif key == "return" then
		if self.activeField == "url" then
			self.currentUrl = self:formatUrl(self.currentUrl)
			table.insert(self.history, self.currentUrl)
			self.historyIndex = #self.history
			self:startLoading()
		elseif self.activeField == "search" then
			self.currentUrl = self:formatUrl(self.searchText)
			table.insert(self.history, self.currentUrl)
			self.historyIndex = #self.history
			self.searchText = ""
			self:startLoading()
		end
		self.activeField = nil
	elseif key == "escape" then
		self.activeField = nil
	end
end

return WebBrowser