local SearchItems = require("data/search_items")

local WebBrowser = {}

function WebBrowser:new()
	local obj = {
		currentUrl = "about:home",
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
		statusMessage = "Ready",
		searchResults = {},
		showSearchResults = false,
		selectedResult = 1,
		hoveredButton = nil,
		hoveredResult = nil,
		colors = {
			background = {0.15, 0.15, 0.15},
			toolbar = {0.2, 0.2, 0.2},
			button = {0.25, 0.25, 0.25},
			buttonHover = {0.3, 0.3, 0.3},
			input = {0.1, 0.1, 0.1},
			text = {0.9, 0.9, 0.9},
			accent = {0.3, 0.6, 0.9},
			statusBar = {0.2, 0.2, 0.2},
			content = {0.12, 0.12, 0.12},
			searchResult = {0.18, 0.18, 0.18},
			searchResultHover = {0.22, 0.22, 0.22},
			dimText = {0.7, 0.7, 0.7}
		},
		contentArea = {
			padding = 20,
			title = "Welcome to the Browser",
			message = "Use the search bar above to find applications or enter a URL"
		}
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function WebBrowser:searchItems(query)
	if query == "" then
		self.searchResults = {}
		self.showSearchResults = false
		return
	end

	self.searchResults = {}
	query = query:lower()
	
	for _, item in ipairs(SearchItems) do
		-- Search in title
		if item.title:lower():find(query, 1, true) then
			table.insert(self.searchResults, item)
		else
			-- Search in keywords
			for _, keyword in ipairs(item.keywords) do
				if keyword:lower():find(query, 1, true) then
					table.insert(self.searchResults, item)
					break
				end
			end
		end
	end
	
	self.showSearchResults = #self.searchResults > 0
	self.selectedResult = 1
end

function WebBrowser:draw(x, y, width, height)
	self.width = width
	self.height = height
	
	-- Draw background
	love.graphics.setColor(unpack(self.colors.background))
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Draw toolbar background
	love.graphics.setColor(unpack(self.colors.toolbar))
	love.graphics.rectangle("fill", x, y, width, self.toolbarHeight)
	
	-- Draw navigation buttons
	self:drawButton("←", x + 10, y + 10, self.historyIndex > 1)
	self:drawButton("→", x + 50, y + 10, self.historyIndex < #self.history)
	self:drawButton("⟳", x + width - 40, y + 10, true)
	
	-- Draw URL bar
	love.graphics.setColor(unpack(self.colors.input))
	love.graphics.rectangle("fill", x + 90, y + 10, width - 140, self.urlBarHeight)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print(self.currentUrl, x + 100, y + 20)
	
	-- Draw search bar
	love.graphics.setColor(unpack(self.colors.input))
	love.graphics.rectangle("fill", x + 10, y + self.urlBarHeight + 10, width - 20, self.searchBarHeight)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print("Search:", x + 20, y + self.urlBarHeight + 20)
	love.graphics.print(self.searchText, x + 100, y + self.urlBarHeight + 20)
	
	-- Draw search results
	if self.showSearchResults and self.searchText ~= "" then
		love.graphics.setColor(unpack(self.colors.input))
		local resultsHeight = #self.searchResults * 40
		love.graphics.rectangle("fill", x + 10, y + self.toolbarHeight, width - 20, resultsHeight)
		
		for i, result in ipairs(self.searchResults) do
			if i == self.selectedResult or i == self.hoveredResult then
				love.graphics.setColor(unpack(self.colors.searchResultHover))
			else
				love.graphics.setColor(unpack(self.colors.searchResult))
			end
			love.graphics.rectangle("fill", x + 10, y + self.toolbarHeight + (i-1)*40, width - 20, 40)
			
			love.graphics.setColor(unpack(self.colors.text))
			love.graphics.print(result.title, x + 20, y + self.toolbarHeight + (i-1)*40 + 10)
			love.graphics.setColor(unpack(self.colors.dimText))
			love.graphics.print(result.description, x + 20, y + self.toolbarHeight + (i-1)*40 + 25)
		end
	end
	
	-- Draw loading bar
	if self.isLoading then
		love.graphics.setColor(unpack(self.colors.accent))
		love.graphics.rectangle("fill", x, y + self.toolbarHeight - 2, width * self.loadingProgress, 2)
	end
	
	-- Draw content area
	love.graphics.setColor(unpack(self.colors.content))
	local contentY = y + self.toolbarHeight
	local contentHeight = height - self.toolbarHeight - self.statusBarHeight
	love.graphics.rectangle("fill", x, contentY, width, contentHeight)
	
	-- Draw content based on URL type
	if self.currentUrl:match("^about:") then
		self:drawAboutPage(x, contentY, width, contentHeight)
	elseif self.currentUrl:match("^app:") then
		self:drawAppPage(x, contentY, width, contentHeight)
	else
		self:drawWebPage(x, contentY, width, contentHeight)
	end

	
	-- Draw status bar
	love.graphics.setColor(unpack(self.colors.statusBar))
	love.graphics.rectangle("fill", x, height - self.statusBarHeight, width, self.statusBarHeight)
	love.graphics.setColor(unpack(self.colors.text))
	local status = self.isLoading and "Loading... " .. math.floor(self.loadingProgress * 100) .. "%" or self.statusMessage
	love.graphics.print(status, x + 10, height - self.statusBarHeight + 5)
	
	-- Draw active field indicator
	if self.activeField then
		love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.3)
		if self.activeField == "url" then
			love.graphics.rectangle("fill", x + 90, y + 10, width - 140, self.urlBarHeight)
		else
			love.graphics.rectangle("fill", x + 10, y + self.urlBarHeight + 10, width - 20, self.searchBarHeight)
		end
	end
end

function WebBrowser:drawButton(text, x, y, enabled)
	local isHovered = (self.hoveredButton == "back" and text == "←") or
					 (self.hoveredButton == "forward" and text == "→") or
					 (self.hoveredButton == "refresh" and text == "⟳")
	
	if enabled then
		if isHovered then
			love.graphics.setColor(unpack(self.colors.buttonHover))
		else
			love.graphics.setColor(unpack(self.colors.button))
		end
	else
		love.graphics.setColor(self.colors.button[1] * 0.7, self.colors.button[2] * 0.7, self.colors.button[3] * 0.7)
	end
	
	love.graphics.rectangle("fill", x, y, self.buttonWidth, self.urlBarHeight)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print(text, x + 10, y + 10)
end

function WebBrowser:mousepressed(x, y, button)
	if button == 1 then
		-- Check search results clicks
		if self.showSearchResults and self.searchText ~= "" then
			local resultY = y - self.toolbarHeight
			local resultIndex = math.floor(resultY / 40) + 1
			if resultIndex >= 1 and resultIndex <= #self.searchResults and
			   x >= 10 and x <= self.width - 10 then
				self.currentUrl = self.searchResults[resultIndex].url
				table.insert(self.history, self.currentUrl)
				self.historyIndex = #self.history
				self.searchText = ""
				self.showSearchResults = false
				self:startLoading()
				return
			end
		end

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
		self:searchItems(self.searchText)
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

function WebBrowser:mousemoved(x, y)
	-- Check button hovers
	if y >= 10 and y <= self.urlBarHeight + 10 then
		if x >= 10 and x <= 40 then
			self.hoveredButton = "back"
		elseif x >= 50 and x <= 80 then
			self.hoveredButton = "forward"
		elseif x >= self.width - 40 and x <= self.width - 10 then
			self.hoveredButton = "refresh"
		else
			self.hoveredButton = nil
		end
	else
		self.hoveredButton = nil
	end
	
	-- Check search result hovers
	if self.showSearchResults and self.searchText ~= "" then
		local resultY = y - (self.toolbarHeight)
		local resultIndex = math.floor(resultY / 40) + 1
		if resultIndex >= 1 and resultIndex <= #self.searchResults and
		   x >= 10 and x <= self.width - 10 then
			self.hoveredResult = resultIndex
		else
			self.hoveredResult = nil
		end
	end
end

function WebBrowser:drawAboutPage(x, y, width, height)
	love.graphics.setColor(unpack(self.colors.text))
	local font = love.graphics.getFont()
	local titleWidth = font:getWidth(self.contentArea.title)
	local messageWidth = font:getWidth(self.contentArea.message)
	
	-- Draw centered title
	love.graphics.print(
		self.contentArea.title,
		x + (width - titleWidth) / 2,
		y + self.contentArea.padding
	)
	
	-- Draw centered message
	love.graphics.print(
		self.contentArea.message,
		x + (width - messageWidth) / 2,
		y + self.contentArea.padding + 40
	)
	
	-- Draw keyboard shortcuts
	local shortcuts = {
		"Keyboard Shortcuts:",
		"Ctrl+L - Focus URL bar",
		"Ctrl+K - Focus search bar",
		"Ctrl+R or F5 - Refresh page",
		"Esc - Clear selection",
		"Enter - Navigate to URL/Search",
		"Up/Down - Navigate search results"
	}
	
	for i, shortcut in ipairs(shortcuts) do
		love.graphics.print(
			shortcut,
			x + self.contentArea.padding,
			y + self.contentArea.padding + 120 + (i-1)*25
		)
	end
end

function WebBrowser:drawAppPage(x, y, width, height)
	love.graphics.setColor(unpack(self.colors.text))
	local appName = self.currentUrl:match("^app:(.+)$")
	love.graphics.print(
		"Opening application: " .. appName,
		x + self.contentArea.padding,
		y + self.contentArea.padding
	)
end

function WebBrowser:drawWebPage(x, y, width, height)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print(
		"Browsing: " .. self.currentUrl,
		x + self.contentArea.padding,
		y + self.contentArea.padding
	)
end

function WebBrowser:keypressed(key)
	-- Handle keyboard shortcuts
	if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
		if key == "l" then
			self.activeField = "url"
			self.currentUrl = ""
			return
		elseif key == "k" then
			self.activeField = "search"
			self.searchText = ""
			return
		elseif key == "r" then
			self:refresh()
			return
		end
	elseif key == "f5" then
		self:refresh()
		return
	end

	if self.showSearchResults then
		if key == "up" then
			self.selectedResult = math.max(1, self.selectedResult - 1)
			return
		elseif key == "down" then
			self.selectedResult = math.min(#self.searchResults, self.selectedResult + 1)
			return
		end
	end

	if key == "backspace" then
		if self.activeField == "url" then
			self.currentUrl = self.currentUrl:sub(1, -2)
		elseif self.activeField == "search" then
			self.searchText = self.searchText:sub(1, -2)
			self:searchItems(self.searchText)
		end
	elseif key == "return" then
		if self.activeField == "url" then
			self.currentUrl = self:formatUrl(self.currentUrl)
			table.insert(self.history, self.currentUrl)
			self.historyIndex = #self.history
			self:startLoading()
		elseif self.activeField == "search" then
			if self.showSearchResults and self.searchResults[self.selectedResult] then
				self.currentUrl = self.searchResults[self.selectedResult].url
				table.insert(self.history, self.currentUrl)
				self.historyIndex = #self.history
				self.searchText = ""
				self.showSearchResults = false
				self:startLoading()
			else
				self.currentUrl = self:formatUrl(self.searchText)
				table.insert(self.history, self.currentUrl)
				self.historyIndex = #self.history
				self.searchText = ""
				self:startLoading()
			end
		end
		self.activeField = nil
	elseif key == "escape" then
		self.activeField = nil
		self.showSearchResults = false
	end
end

return WebBrowser