local SearchItems = require("data/search_items")
local Terminal = require("apps/terminal")
local FileManager = require("apps/file_manager")
local EmailClient = require("apps/email_client")
local LinkedInSite = require("websites/linkedin")

local WebBrowser = {}

function WebBrowser:new()
	local obj = {
		searchText = "",
		width = 0,
		height = 0,
		activeField = nil,
		searchBarHeight = 50,
		toolbarHeight = 70,
		history = {},
		currentHistoryIndex = 0,
		searchResults = {},
		showSearchResults = false,
		selectedResult = 1,
		hoveredResult = nil,
		expandedResults = nil,
		cursorPos = 0,
		cursorVisible = true,
		cursorBlinkTime = 0,
		isLoading = false,
		loadingTimer = 0,
		loadingDots = "",
		loadingDotsTimer = 0,
		currentWebsite = nil,
		colors = {
			background = {0.15, 0.15, 0.15},
			toolbar = {0.2, 0.2, 0.2},
			input = {0.1, 0.1, 0.1},
			inputBorder = {0.3, 0.3, 0.3},
			inputFocus = {0.4, 0.4, 0.4},
			text = {0.9, 0.9, 0.9},
			dimText = {0.7, 0.7, 0.7},
			accent = {0.3, 0.6, 0.9},
			searchResult = {0.18, 0.18, 0.18},
			searchResultHover = {0.22, 0.22, 0.22},
			linkText = {0.4, 0.7, 1.0},
			linkHover = {0.5, 0.8, 1.0}
		},
		contentArea = {
			padding = 20,
			title = "LÖVE Search",
			message = "Search for LÖVE documentation, tutorials, and system applications"
		}
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function WebBrowser:searchItems(query)
	self.isLoading = true
	self.loadingTimer = 0
	self.searchResults = {
		{
			title = "John Doe - Software Engineer - LinkedIn",
			description = "Software Engineer with 5+ years of experience in full-stack development. Currently working at Tech Corp, leading development of web applications and scalable services.",
			url = "linkedin/profile/johndoe"
		},
		{
			title = "Software Engineering Jobs in Tech Corp | LinkedIn",
			description = "1,500+ Software Engineering jobs available. Join our growing team of developers and help build the next generation of technology solutions.",
			url = "linkedin/jobs/tech-corp"
		},
		{
			title = "Tech Corp Company Page | LinkedIn",
			description = "Tech Corp is a leading software company specializing in innovative solutions. Follow us to stay updated with our latest projects and job opportunities.",
			url = "linkedin/company/tech-corp"
		}
	}
end


function WebBrowser:draw(x, y, width, height)
	self.width = width
	self.height = height

	love.graphics.setColor(unpack(self.colors.background))
	love.graphics.rectangle("fill", x, y, width, height)
	
	love.graphics.setColor(unpack(self.colors.toolbar))
	love.graphics.rectangle("fill", x, y, width, self.toolbarHeight)
	
	-- Draw back/forward buttons
	local buttonWidth = 30
	local buttonHeight = 30
	local buttonY = y + 20
	
	-- Back button
	if #self.history > 0 and self.currentHistoryIndex > 1 then
		love.graphics.setColor(unpack(self.colors.accent))
	else
		love.graphics.setColor(0.3, 0.3, 0.3) -- Disabled color
	end
	love.graphics.rectangle("fill", x + 20, buttonY, buttonWidth, buttonHeight)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print("←", x + 30, buttonY + 5)
	
	-- Forward button
	if self.currentHistoryIndex < #self.history then
		love.graphics.setColor(unpack(self.colors.accent))
	else
		love.graphics.setColor(0.3, 0.3, 0.3) -- Disabled color
	end
	love.graphics.rectangle("fill", x + 60, buttonY, buttonWidth, buttonHeight)
	love.graphics.setColor(unpack(self.colors.text))
	love.graphics.print("→", x + 70, buttonY + 5)
	
	local searchY = y + 10
	love.graphics.setColor(unpack(self.colors.input))
	love.graphics.rectangle("fill", x + 20, searchY, width - 40, self.searchBarHeight)
	if self.activeField == "search" then
		love.graphics.setColor(unpack(self.colors.inputFocus))
	else
		love.graphics.setColor(unpack(self.colors.inputBorder))
	end
	love.graphics.rectangle("line", x + 20, searchY, width - 40, self.searchBarHeight)
	
	if self.searchText == "" then
		love.graphics.setColor(unpack(self.colors.dimText))
		love.graphics.print("Search LÖVE documentation and apps...", x + 115, searchY + 15)
	else
		love.graphics.setColor(unpack(self.colors.text))
		local beforeCursor = self.searchText:sub(1, self.cursorPos)
		local afterCursor = self.searchText:sub(self.cursorPos + 1)
		love.graphics.print(beforeCursor, x + 115, searchY + 15)
		
		-- Draw blinking cursor
		if self.activeField == "search" and self.cursorVisible then
			local cursorX = x + 115 + love.graphics.getFont():getWidth(beforeCursor)
			love.graphics.rectangle("fill", cursorX, searchY + 15, 2, 20)
		end
		
		love.graphics.print(afterCursor, x + 115 + love.graphics.getFont():getWidth(beforeCursor), searchY + 15)
	end
	
	-- Draw loading indicator if loading
	if self.isLoading then
		love.graphics.setColor(unpack(self.colors.text))
		local loadingText = "Searching" .. self.loadingDots
		local font = love.graphics.getFont()
		local textWidth = font:getWidth(loadingText)
		love.graphics.print(loadingText, x + (width - textWidth)/2, y + self.toolbarHeight + 50)
		return
	end

	-- Draw current website if active
	if self.currentWebsite then
		self.currentWebsite:draw(x, y + self.toolbarHeight, width, height - self.toolbarHeight)
		return
	end

	if self.showSearchResults and self.searchText ~= "" then
		self:drawSearchResults(x, y + self.toolbarHeight + 10, width)
	else
		self:drawWelcomePage(x, y + self.toolbarHeight, width, height - self.toolbarHeight)
	end
end

function WebBrowser:launchSystemApp(app)
	if app == "terminal" then
		return Terminal:new()
	elseif app == "files" then
		return FileManager:new()
	elseif app == "email" then
		return EmailClient:new()
	end
	return nil
end

function WebBrowser:mousepressed(x, y, button)
	if button == 1 then
		-- Calculate search bar area relative to window position
		local searchY = 10
		local searchBarBottom = searchY + self.searchBarHeight

		-- Check if click is in search bar area
		if y >= searchY and y <= searchBarBottom and
		   x >= 20 and x <= self.width - 20 then
			self.activeField = "search"
			-- Calculate cursor position based on click position relative to text start
			local textStartX = 35
			local clickX = x - textStartX
			local text = self.searchText
			local font = love.graphics.getFont()
			
			if clickX <= 0 then
				self.cursorPos = 0
			else
				for i = 0, #text do
					local textWidth = font:getWidth(text:sub(1, i))
					if clickX <= textWidth then
						self.cursorPos = i
						break
					end
					if i == #text then
						self.cursorPos = #text
					end
				end
			end
			self.cursorVisible = true
			self.cursorBlinkTime = 0
			return true
		end

		-- Check if back button clicked
		local buttonY = 20
		if y >= buttonY and y <= buttonY + 30 then
			if x >= 20 and x <= 50 then
				self:navigateBack()
				return true
			elseif x >= 60 and x <= 90 then
				self:navigateForward()
				return true
			end
		end

		-- Handle search results area clicks
		if self.showSearchResults and not self.currentWebsite then
			local resultsY = self.toolbarHeight + 50
			for i, result in ipairs(self.searchResults) do
				if y >= resultsY and y <= resultsY + 80 and
				   x >= 20 and x <= self.width - 20 then
					if result.url:match("^linkedin") then
						local newWebsite = LinkedInSite:new()
						newWebsite.currentPage = result.url:match("linkedin/(.+)") or ""
						self:navigateTo(newWebsite)
					end
					return
				end
				resultsY = resultsY + 90
			end
		end

		
		self.activeField = nil
	end
end


function WebBrowser:textinput(text)
	if self.activeField == "search" then
		local before = self.searchText:sub(1, self.cursorPos)
		local after = self.searchText:sub(self.cursorPos + 1)
		self.searchText = before .. text .. after
		self.cursorPos = self.cursorPos + #text
		return true
	end
	return false
end


function WebBrowser:mousemoved(x, y)
	-- Update search bar hover detection
	local searchY = 10
	local searchBarBottom = searchY + self.searchBarHeight

	if y >= searchY and y <= searchBarBottom and
	   x >= 20 and x <= self.width - 20 then
		love.mouse.setCursor(love.mouse.getSystemCursor("ibeam"))
		return
	end
	
	if self.showSearchResults then
		local resultsY = self.toolbarHeight + 10
		for i, result in ipairs(self.searchResults) do
			local isExpanded = self.expandedResults == i
			local itemHeight = isExpanded and (80 + #result.results * 60) or 80
			
			if y >= resultsY and y <= resultsY + itemHeight and
			   x >= 20 and x <= self.width - 20 then
				self.hoveredResult = i
				
				if isExpanded and result.results then
					for j, subResult in ipairs(result.results) do
						local subY = resultsY + 80 + (j-1) * 60
						if y >= subY and y <= subY + 50 then
							love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
							return
						end
					end
				end
				return
			end
			resultsY = resultsY + itemHeight + 10
		end
		self.hoveredResult = nil
	end
	
	love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
end


function WebBrowser:drawSearchResults(x, y, width)
	-- Draw search stats
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.print("About " .. #self.searchResults .. " results (0.42 seconds)", x + 20, y - 30)
	
	for i, result in ipairs(self.searchResults) do
		-- Draw result background
		if i == self.hoveredResult then
			love.graphics.setColor(unpack(self.colors.searchResultHover))
		else
			love.graphics.setColor(unpack(self.colors.searchResult))
		end
		love.graphics.rectangle("fill", x + 20, y, width - 40, 80)
		
		-- Draw title with underline effect on hover
		love.graphics.setColor(unpack(self.colors.linkText))
		love.graphics.print(result.title, x + 40, y + 15)
		if i == self.hoveredResult then
			local titleWidth = love.graphics.getFont():getWidth(result.title)
			love.graphics.line(x + 40, y + 35, x + 40 + titleWidth, y + 35)
		end
		
		-- Draw URL in green with favicon
		love.graphics.setColor(0.2, 0.8, 0.2)
		love.graphics.print("🔗 " .. result.url, x + 40, y + 40)
		
		-- Draw description
		love.graphics.setColor(unpack(self.colors.dimText))
		love.graphics.printf(result.description, x + 40, y + 55, width - 80)
		
		y = y + 90
	end
end


function WebBrowser:drawWelcomePage(x, y, width, height)
	love.graphics.setColor(unpack(self.colors.text))
	local font = love.graphics.getFont()
	local titleWidth = font:getWidth(self.contentArea.title)
	local messageWidth = font:getWidth(self.contentArea.message)
	
	love.graphics.print(
		self.contentArea.title,
		x + (width - titleWidth) / 2,
		y + 50
	)
	
	love.graphics.setColor(unpack(self.colors.dimText))
	love.graphics.print(
		self.contentArea.message,
		x + (width - messageWidth) / 2,
		y + 100
	)
	
	love.graphics.print("Try searching for:", x + 40, y + 180)
	local suggestions = {
		"• Tutorials and getting started guides",
		"• API documentation and references", 
		"• Game development resources",
		"• System applications"
	}
	
	for i, suggestion in ipairs(suggestions) do
		love.graphics.print(suggestion, x + 60, y + 210 + (i-1) * 30)
	end
end

function WebBrowser:drawAboutPage(x, y, width, height)
	self:drawWelcomePage(x, y, width, height)
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
		"Opening web page: " .. self.currentUrl,
		x + self.contentArea.padding,
		y + self.contentArea.padding
	)
end

function WebBrowser:update(dt)
	-- Update cursor blinking
	self.cursorBlinkTime = (self.cursorBlinkTime or 0) + dt
	if self.cursorBlinkTime >= 0.5 then
		self.cursorBlinkTime = 0
		self.cursorVisible = not self.cursorVisible
	end

	-- Update loading state
	if self.isLoading then
		self.loadingTimer = self.loadingTimer + dt
		self.loadingDotsTimer = self.loadingDotsTimer + dt
		
		-- Update loading animation
		if self.loadingDotsTimer >= 0.3 then
			self.loadingDotsTimer = 0
			if #self.loadingDots < 3 then
				self.loadingDots = self.loadingDots .. "."
			else
				self.loadingDots = ""
			end
		end

		if self.loadingTimer >= 1.5 then
			self.isLoading = false
			self.showSearchResults = true
			self.loadingDots = ""
		end
	end
end

function WebBrowser:keypressed(key)
	if key == "escape" then
		if self.currentWebsite then
			self.currentWebsite = nil
		else
			self.activeField = nil
			self.showSearchResults = false
			self.searchText = ""
			self.cursorPos = 0
		end
	elseif key == "return" and self.activeField == "search" then
		if self.searchText ~= "" then
			self:searchItems(self.searchText)
		end
	elseif key == "backspace" then
		if self.activeField == "search" and self.cursorPos > 0 then
			local before = self.searchText:sub(1, self.cursorPos - 1)
			local after = self.searchText:sub(self.cursorPos + 1)
			self.searchText = before .. after
			self.cursorPos = self.cursorPos - 1
			self:searchItems(self.searchText)
		end
	elseif key == "left" and self.activeField == "search" then
		self.cursorPos = math.max(0, self.cursorPos - 1)
	elseif key == "right" and self.activeField == "search" then
		self.cursorPos = math.min(#self.searchText, self.cursorPos + 1)
	elseif key == "return" then
		if self.activeField == "search" and self.showSearchResults then
			local result = self.searchResults[self.selectedResult]
			if result then
				if result.url:match("^search:") then
					self.expandedResults = self.expandedResults == self.selectedResult and nil or self.selectedResult
				end
			end
		end
	elseif key == "up" and self.showSearchResults then
		self.selectedResult = math.max(1, self.selectedResult - 1)
	elseif key == "down" and self.showSearchResults then
		self.selectedResult = math.min(#self.searchResults, self.selectedResult + 1)
	end
end

function WebBrowser:navigateTo(website)
	-- Add new page to history
	if self.currentHistoryIndex < #self.history then
		-- Remove forward history if we're navigating from middle
		for i = #self.history, self.currentHistoryIndex + 1, -1 do
			table.remove(self.history, i)
		end
	end
	
	self.currentWebsite = website
	self.showSearchResults = false
	table.insert(self.history, website)
	self.currentHistoryIndex = #self.history
end

function WebBrowser:navigateBack()
	if self.currentHistoryIndex > 1 then
		self.currentHistoryIndex = self.currentHistoryIndex - 1
		self.currentWebsite = self.history[self.currentHistoryIndex]
		self.showSearchResults = false
	end
end

function WebBrowser:navigateForward()
	if self.currentHistoryIndex < #self.history then
		self.currentHistoryIndex = self.currentHistoryIndex + 1
		self.currentWebsite = self.history[self.currentHistoryIndex]
		self.showSearchResults = false
	end
end

return WebBrowser
