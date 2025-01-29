local WebBrowser = {}

function WebBrowser:new()
	local obj = {
		-- Browser state
		currentURL = "home",
		urlInput = "",
		history = {"home"},
		historyIndex = 1,
		isEditing = false,
		
		-- Pages content
		pages = {
			home = {
				title = "Home",
				content = [[
Welcome to the Hacker Browser
============================

Quick Links:
- Network Tools
- Encryption Services
- Vulnerability Scanner
- System Diagnostics
				]],
				links = {
					["Network Tools"] = "network",
					["Encryption Services"] = "encryption",
					["Vulnerability Scanner"] = "scanner",
					["System Diagnostics"] = "diagnostics"
				}
			},
			network = {
				title = "Network Tools",
				content = [[
Network Analysis Tools
====================

- Port Scanner
- Network Monitor
- Traffic Analyzer
- Packet Inspector
				]],
				links = {
					["Home"] = "home"
				}
			},
			encryption = {
				title = "Encryption Services",
				content = [[
Encryption Tools
==============

- File Encryption
- Message Encryption
- Key Generator
- Hash Calculator
				]],
				links = {
					["Home"] = "home"
				}
			},
			scanner = {
				title = "Vulnerability Scanner",
				content = [[
System Vulnerability Scanner
=========================

- Quick Scan
- Deep Scan
- Custom Scan
- Scan History
				]],
				links = {
					["Home"] = "home"
				}
			},
			diagnostics = {
				title = "System Diagnostics",
				content = [[
System Diagnostics Tools
=====================

- System Info
- Process Monitor
- Resource Usage
- Log Analyzer
				]],
				links = {
					["Home"] = "home"
				}
			}
		}
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function WebBrowser:draw(x, y, width, height)
	-- Store dimensions
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	
	local default_font = love.graphics.getFont()
	local font = love.graphics.newFont("joty.otf", 18)
	font:setFilter("nearest", "nearest")
	love.graphics.setFont(font)
	
	-- Draw browser background
	love.graphics.setColor(1, 1, 1, 0.9)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Draw navigation bar
	love.graphics.setColor(0.95, 0.95, 0.95)
	love.graphics.rectangle("fill", x, y, width, 50)
	
	-- Draw back/forward buttons
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", x + 10, y + 10, 30, 30)
	love.graphics.rectangle("fill", x + 50, y + 10, 30, 30)
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.print("←", x + 17, y + 15)
	love.graphics.print("→", x + 57, y + 15)
	
	-- Draw URL bar
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", x + 90, y + 10, width - 100, 30)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(self.isEditing and self.urlInput or self.currentURL,
		x + 100, y + 15)
	
	-- Draw page content
	local page = self.pages[self.currentURL]
	if page then
		-- Draw title
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(page.title, x + 20, y + 70)
		
		-- Draw content
		love.graphics.printf(page.content, x + 20, y + 100, width - 40)
		
		-- Draw links
		local linkY = y + 300
		for text, url in pairs(page.links) do
			love.graphics.setColor(0.2, 0.4, 0.8)
			love.graphics.print(text, x + 20, linkY)
			linkY = linkY + 30
		end
	end
	
	love.graphics.setFont(default_font)
end

function WebBrowser:mousepressed(x, y, button)
	if button == 1 then
		-- All coordinates are already relative to content area
		-- Check back button
		if y >= 10 and y <= 40 then
			if x >= 10 and x <= 40 then
				if self.historyIndex > 1 then
					self.historyIndex = self.historyIndex - 1
					self.currentURL = self.history[self.historyIndex]
				end
				return true
			end
			
			-- Check forward button
			if x >= 50 and x <= 80 then
				if self.historyIndex < #self.history then
					self.historyIndex = self.historyIndex + 1
					self.currentURL = self.history[self.historyIndex]
				end
				return true
			end
			
			-- Check URL bar
			if x >= 90 and x <= self.width - 10 then
				self.isEditing = true
				self.urlInput = self.currentURL
				return true
			end
		end
		
		-- Check links
		local page = self.pages[self.currentURL]
		if page then
			local linkY = 300
			for text, url in pairs(page.links) do
				if y >= linkY and y <= linkY + 25 and
				   x >= 20 and x <= 200 then
					self:navigate(url)
					return true
				end
				linkY = linkY + 30
			end
		end
	end
	return false
end


function WebBrowser:navigate(url)
	if self.pages[url] then
		self.currentURL = url
		while #self.history > self.historyIndex do
			table.remove(self.history)
		end
		table.insert(self.history, url)
		self.historyIndex = #self.history
	end
end

function WebBrowser:textinput(text)
	if self.isEditing then
		self.urlInput = self.urlInput .. text
	end
end

function WebBrowser:keypressed(key)
	if self.isEditing then
		if key == "return" then
			if self.pages[self.urlInput] then
				self:navigate(self.urlInput)
			end
			self.isEditing = false
		elseif key == "escape" then
			self.isEditing = false
		elseif key == "backspace" then
			self.urlInput = self.urlInput:sub(1, -2)
		end
	end
end

function WebBrowser:update(dt)
    -- Add any animation or state updates here if needed
end

return WebBrowser
