local SearchItems = require("data/search_items")
local Terminal = require("apps/terminal")
local FileManager = require("apps/file_manager")
local EmailClient = require("apps/email_client")

local WebBrowser = {}

function WebBrowser:new()
	local obj = {
		searchText = "",
		width = 0,
		height = 0,
		activeField = nil,
		searchBarHeight = 50,
		toolbarHeight = 70,
		searchResults = {},
		showSearchResults = false,
		selectedResult = 1,
		hoveredResult = nil,
		expandedResults = nil,
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
	if query == "" then
		self.searchResults = {}
		self.showSearchResults = false
		return
	end

	self.searchResults = {}
	query = query:lower()
	
	for _, item in ipairs(SearchItems) do
		if item.title:lower():find(query, 1, true) or
		   item.description:lower():find(query, 1, true) then
			table.insert(self.searchResults, item)
		else
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
	self.expandedResults = nil
end

function WebBrowser:draw(x, y, width, height)
	love.graphics.setColor(unpack(self.colors.background))
	love.graphics.rectangle("fill", x, y, width, height)
	
	love.graphics.setColor(unpack(self.colors.toolbar))
	love.graphics.rectangle("fill", x, y, width, self.toolbarHeight)
	
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
		love.graphics.print("Search LÖVE documentation and apps...", x + 35, searchY + 15)
	else
		love.graphics.setColor(unpack(self.colors.text))
		love.graphics.print(self.searchText, x + 35, searchY + 15)
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
		local searchY = y - 10
		if searchY >= 0 and searchY <= self.searchBarHeight and
		   x >= 20 and x <= self.width - 20 then
			self.activeField = "search"
			return
		end
		
		if self.showSearchResults then
			local resultsY = self.toolbarHeight + 10
			for i, result in ipairs(self.searchResults) do
				local isExpanded = self.expandedResults == i
				local itemHeight = isExpanded and (80 + #result.results * 60) or 80
				
				if y >= resultsY and y <= resultsY + itemHeight and
				   x >= 20 and x <= self.width - 20 then
					if result.url:match("^search:") then
						self.expandedResults = self.expandedResults == i and nil or i
					end
					
					if isExpanded and result.results then
						for j, subResult in ipairs(result.results) do
							local subY = resultsY + 80 + (j-1) * 60
							if y >= subY and y <= subY + 50 and
							   x >= 60 and x <= self.width - 40 then
								if subResult.url:match("^app:") then
									local app = subResult.url:match("^app:(.+)$")
									local appInstance = self:launchSystemApp(app)
									if appInstance and _G.windowManager then
										_G.windowManager:createWindow(app:gsub("^%l", string.upper), appInstance)
									end
								else
									love.system.openURL(subResult.url)
								end
								self.searchText = ""
								self.showSearchResults = false
								return
							end
						end
					end
					return
				end
				resultsY = resultsY + itemHeight + 10
			end
		end
		
		self.activeField = nil
	end
end

function WebBrowser:textinput(text)
	if self.activeField == "search" then
		self.searchText = self.searchText .. text
		self:searchItems(self.searchText)
	end
end

function WebBrowser:mousemoved(x, y)
	local searchY = y - 10
	if searchY >= 0 and searchY <= self.searchBarHeight and
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
	for i, result in ipairs(self.searchResults) do
		local isExpanded = self.expandedResults == i
		local itemHeight = isExpanded and (80 + #result.results * 60) or 80
		
		if i == self.selectedResult or i == self.hoveredResult then
			love.graphics.setColor(unpack(self.colors.searchResultHover))
		else
			love.graphics.setColor(unpack(self.colors.searchResult))
		end
		love.graphics.rectangle("fill", x + 20, y, width - 40, itemHeight)
		
		love.graphics.setColor(unpack(self.colors.text))
		love.graphics.print(result.title, x + 40, y + 15)
		love.graphics.setColor(unpack(self.colors.dimText))
		love.graphics.print(result.description, x + 40, y + 40)
		
		if isExpanded and result.results then
			for j, subResult in ipairs(result.results) do
				local subY = y + 80 + (j-1) * 60
				if self.hoveredResult == i and 
				   love.mouse.getY() >= subY and 
				   love.mouse.getY() <= subY + 50 then
					love.graphics.setColor(unpack(self.colors.linkHover))
				else
					love.graphics.setColor(unpack(self.colors.linkText))
				end
				love.graphics.print(subResult.title, x + 60, subY)
				love.graphics.setColor(unpack(self.colors.dimText))
				love.graphics.print(subResult.description, x + 60, subY + 25)
			end
		end
		
		y = y + itemHeight + 10
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

function WebBrowser:keypressed(key)
	if key == "escape" then
		self.activeField = nil
		self.showSearchResults = false
		self.searchText = ""
	elseif key == "backspace" then
		if self.activeField == "search" then
			self.searchText = self.searchText:sub(1, -2)
			self:searchItems(self.searchText)
		end
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

return WebBrowser
