local WebBrowser = {}

-- Hover state tracking
local hover = {
	button = nil,
	link = nil
}

-- Icon drawing functions
local function drawLockIcon(x, y, size)
	love.graphics.rectangle("line", x, y, size, size * 1.2)
	love.graphics.rectangle("fill", x + size * 0.2, y + size * 0.4, size * 0.6, size * 0.8)
	love.graphics.circle("fill", x + size * 0.5, y + size * 0.4, size * 0.2)
end

local function drawSearchIcon(x, y, size)
	love.graphics.circle("line", x + size * 0.4, y + size * 0.4, size * 0.3)
	love.graphics.setLineWidth(2)
	love.graphics.line(x + size * 0.6, y + size * 0.6, x + size * 0.8, y + size * 0.8)
	love.graphics.setLineWidth(1)
end

local function drawLinkIcon(x, y, size)
	love.graphics.setLineWidth(2)
	love.graphics.arc("line", x + size * 0.3, y + size * 0.5, size * 0.2, 0, math.pi)
	love.graphics.arc("line", x + size * 0.7, y + size * 0.5, size * 0.2, math.pi, math.pi * 2)
	love.graphics.setLineWidth(1)
end

local function drawSearchBox(x, y, w, h, text, placeholder, isActive)
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h, h/2, h/2)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("line", x, y, w, h, h/2, h/2)
    
    -- Draw search icon
    love.graphics.setColor(0.6, 0.6, 0.6)
    drawSearchIcon(x + 10, y + h/4, h/2)
    
    -- Draw text
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text ~= "" and text or placeholder, x + h, y + h/4)
end

local function drawMessageInput(x, y, w, h, text, placeholder, isActive)
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    
    -- Draw text
    love.graphics.setColor(text ~= "" and {0, 0, 0} or {0.7, 0.7, 0.7})
    love.graphics.print(text ~= "" and text or placeholder, x + 15, y + h/4)
end

local function drawVerifiedIcon(x, y, size)
	love.graphics.setLineWidth(2)
	love.graphics.circle("line", x + size * 0.5, y + size * 0.5, size * 0.4)
	love.graphics.line(x + size * 0.3, y + size * 0.5, x + size * 0.45, y + size * 0.65)
	love.graphics.line(x + size * 0.45, y + size * 0.65, x + size * 0.7, y + size * 0.35)
	love.graphics.setLineWidth(1)
end

local function drawFolderIcon(x, y, size)
	love.graphics.rectangle("line", x, y + size * 0.2, size, size * 0.6)
	love.graphics.line(x, y + size * 0.2, x + size * 0.3, y)
	love.graphics.line(x + size * 0.3, y, x + size * 0.7, y)
	love.graphics.line(x + size * 0.7, y, x + size, y + size * 0.2)
end

local function drawButton(x, y, w, h, text, isActive)
    local isHovered = hover.button and 
        x <= hover.button.x and hover.button.x <= x + w and
        y <= hover.button.y and hover.button.y <= y + h
    
    love.graphics.setColor(isActive and 
        (isHovered and {0.4, 0.6, 1.0} or {0.3, 0.5, 0.9}) or 
        (isHovered and {0.85, 0.85, 0.85} or {0.8, 0.8, 0.8}))
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    love.graphics.setColor(isActive and {1, 1, 1} or {0.3, 0.3, 0.3})
    local textWidth = love.graphics.getFont():getWidth(text)
    local textHeight = love.graphics.getFont():getHeight()
    love.graphics.print(text, x + (w - textWidth)/2, y + (h - textHeight)/2)
end

-- Helper functions to generate content
local function generateSearchResults(query)
	if not query or query == "" then
		return {}
	end

	local results = {
		{
			title = "Advanced Network Penetration Techniques",
			url = "network/pentest-guide",
			description = "Comprehensive guide to network penetration testing, including advanced techniques and tools.",
			relevance = 95,
			date = os.time() - 86400, -- 1 day ago
			popularity = 98,
			verified = true,
			highSecurity = true,
			category = "Network Security"
		},
		{
			title = "Zero-Day Vulnerability Database",
			url = "security/vulnerabilities",
			description = "Latest zero-day vulnerabilities and exploits. Updated daily with new security threats.",
			relevance = 92,
			date = os.time() - 3600, -- 1 hour ago
			popularity = 95,
			verified = true,
			highSecurity = true,
			category = "Exploit Development"
		},
		{
			title = "Encryption Methods in Cybersecurity",
			url = "security/encryption",
			description = "Analysis of modern encryption methods used in cybersecurity applications.",
			relevance = 88,
			date = os.time() - 604800, -- 1 week ago
			popularity = 85,
			verified = true,
			highSecurity = false,
			category = "Cryptography"
		},
		{
			title = "Ethical Hacking Certification Guide",
			url = "training/certification",
			description = "Complete guide to ethical hacking certifications and career paths.",
			relevance = 85,
			date = os.time() - 2592000, -- 1 month ago
			popularity = 90,
			verified = true,
			highSecurity = false,
			category = "Security"
		},
		{
			title = "Malware Analysis Techniques",
			url = "security/malware-analysis",
			description = "Advanced techniques for analyzing and understanding malware behavior.",
			relevance = 82,
			date = os.time() - 172800, -- 2 days ago
			popularity = 88,
			verified = true,
			highSecurity = true,
			category = "Malware Analysis"
		}
	}
	
	-- Filter results based on query
	local filtered = {}
	for _, result in ipairs(results) do
		if result.title:lower():find(query:lower()) or 
		   result.description:lower():find(query:lower()) or
		   result.category:lower():find(query:lower()) then
			table.insert(filtered, result)
		end
	end
	return filtered
end

local function generateMessages()
	return {
		{
			channel = "Project Alpha",
			online = 5,
			messages = {
				{ user = "CyberPro", text = "Found a critical vulnerability in the target system", time = "14:23", encrypted = true },
				{ user = "HackMaster", text = "Running analysis on the vulnerability now", time = "14:24", encrypted = true },
				{ user = "SecurityGuru", text = "I'll verify the exploit path", time = "14:25", encrypted = true },
				{ user = "NetRunner", text = "Checking for similar patterns in other systems", time = "14:26", encrypted = true }
			}
		},
		{
			channel = "Security Research",
			online = 3,
			messages = {
				{ user = "DataWizard", text = "New quantum encryption breakthrough paper", time = "13:15", encrypted = true },
				{ user = "CipherMaster", text = "Analyzing the implications for current systems", time = "13:17", encrypted = true },
				{ user = "QuantumHacker", text = "This could revolutionize our approach to encryption", time = "13:20", encrypted = true }
			}
		},
		{
			channel = "Vulnerability Disclosure",
			online = 8,
			messages = {
				{ user = "BugHunter", text = "Critical zero-day found in popular framework", time = "15:01", encrypted = true },
				{ user = "SecOps", text = "Beginning impact assessment", time = "15:03", encrypted = true },
				{ user = "PatchMaster", text = "Working on emergency mitigation", time = "15:05", encrypted = true }
			}
		}
	}
end

local function generatePosts()
	return {
		{
			user = "CyberPro",
			content = "Just discovered a new vulnerability in OpenSSL. Working on a detailed report. #CyberSecurity",
			likes = 145,
			comments = 23,
			timestamp = "2 hours ago"
		},
		{
			user = "HackMaster",
			content = "Hosting a workshop on advanced penetration testing next week. DM for details! #Hacking #Workshop",
			likes = 89,
			comments = 15,
			timestamp = "5 hours ago"
		},
		{
			user = "SecurityGuru",
			content = "Released a new tool for network analysis. Check it out on my GitHub! #Tools #NetSec",
			likes = 234,
			comments = 45,
			timestamp = "1 day ago"
		}
	}
end

function WebBrowser:new()
	local obj = {
		-- Browser state
		currentURL = "home",
		urlInput = "",
		history = {"home"},
		historyIndex = 1,
		isEditing = false,
		isSearching = false,
		searchText = nil,
		
		-- Pages content
		pages = {
			home = {
				title = "HackerSearch",
				content = [[
HackerSearch
===========

The Hacker's Search Engine
Secure. Anonymous. Powerful.

[Search Box]
				]],
				links = {
					["Advanced Search"] = "advanced_search",
					["Security Tools"] = "tools",
					["Recent Searches"] = "history"
				},
				isSearch = true
			},
			advanced_search = {
				title = "Advanced Search",
				content = [[
Advanced Search Options
=====================

Search Filters:
□ Network Security
□ Exploit Development
□ Malware Analysis
□ Cryptography
□ Forensics

Time Range:
○ Any time
○ Past 24 hours
○ Past week
○ Past month
○ Custom range

Sort By:
○ Relevance
○ Date
○ Popularity

Security Level:
○ All Results
○ Verified Sources Only
○ High Security Only

[Search Box]
				]],
				links = {
					["Basic Search"] = "home",
					["Search History"] = "history"
				},
				isSearch = true,
				interactive = {
					toggleFilter = function(self, filter)
						self.activeFilters = self.activeFilters or {}
						self.activeFilters[filter] = not self.activeFilters[filter]
					end,
					setTimeRange = function(self, range)
						self.timeRange = range
					end,
					setSortBy = function(self, sort)
						self.sortBy = sort
					end,
					setSecurityLevel = function(self, level)
						self.securityLevel = level
					end
				}
			},
			search_results = {
				title = "Search Results",
				content = "",
				links = {
					["Back to Search"] = "home"
				}
			},
			social = {
				title = "Social Hub",
				content = [[
Social Hub
=========

Connect with other hackers and security professionals:

- HackerNet (Professional Network)
- SecureChat (Encrypted Messaging)
- CodeShare (Project Collaboration)
				]],
				links = {
					["Home"] = "home",
					["HackerNet"] = "hackernet",
					["SecureChat"] = "securechat",
					["CodeShare"] = "codeshare"
				}
			},
			hackernet = {
				title = "HackerNet",
				content = function(self)
					local posts = generatePosts()
					local content = [[
HackerNet - Professional Network
==============================

Your Profile
-----------
@WhiteHat
Skills: Network Security, Penetration Testing
Reputation: ★★★★☆
Connections: 150

Recent Posts
-----------
]]
					for _, post in ipairs(posts) do
						content = content .. string.format([[

%s (@%s) - %s
%s
Likes: %d   Comments: %s
]], post.user, post.user:lower(), post.timestamp, post.content, post.likes, post.comments)
					end
					return content
				end,
				links = {
					["Home"] = "home",
					["Profile"] = "profile",
					["Messages"] = "messages",
					["New Post"] = "new_post"
				},
				interactive = {
					like = function(self, postIndex)
						local posts = generatePosts()
						if posts[postIndex] then
							posts[postIndex].likes = posts[postIndex].likes + 1
						end
					end,
					comment = function(self, postIndex)
						self.commenting = postIndex
					end
				}
			},
			securechat = {
				title = "SecureChat",
				content = function(self)
					local chats = generateMessages()
					local content = [[
SecureChat - End-to-End Encrypted Messaging
=========================================

Active Channels:
]]
					for _, chat in ipairs(chats) do
						content = content .. string.format("\n[Active] %s (%d online) - [Encrypted]\n", chat.channel, chat.online)
						if self.activeChat == chat.channel then
							content = content .. "\nMessages:\n"
							for _, msg in ipairs(chat.messages) do
								local encryptedStatus = msg.encrypted and "[Encrypted] " or ""
								content = content .. string.format("[%s] %s%s: %s\n", 
									msg.time, encryptedStatus, msg.user, msg.text)
							end
							content = content .. "\n[Encrypted Message Input]"
						end
					end
					return content
				end,
				links = {
					["Home"] = "home",
					["New Chat"] = "new_chat",
					["Settings"] = "chat_settings"
				},
				interactive = {
					selectChat = function(self, channel)
						self.activeChat = channel
						self.isTyping = false
						self.messageText = ""
					end,
					startTyping = function(self)
						self.isTyping = true
						self.messageText = self.messageText or ""
					end,
					sendMessage = function(self, text)
						if self.activeChat then
							local chats = generateMessages()
							for _, chat in ipairs(chats) do
								if chat.channel == self.activeChat then
									table.insert(chat.messages, {
										user = "You",
										text = text,
										time = os.date("%H:%M")
									})
									break
								end
							end
						end
						self.isTyping = false
						self.messageText = ""
					end
				}
			},
			tools = {
				title = "Hacking Tools",
				content = [[
Hacking Tools
===========

- Network Analysis
- Encryption Tools
- Vulnerability Scanners
- Security Auditing
				]],
				links = {
					["Home"] = "home",
					["Network Tools"] = "network",
					["Encryption"] = "encryption",
					["Scanner"] = "scanner"
				}
			}
		}
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function WebBrowser:mousemoved(x, y)
	hover.button = {x = x, y = y}
	hover.link = {x = x, y = y}
end

function WebBrowser:draw(x, y, width, height)
	-- Store dimensions
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	
	local default_font = love.graphics.getFont()
	local font = love.graphics.newFont("fonts/firaCode.ttf", 16)
	font:setFilter("nearest", "nearest")
	love.graphics.setFont(font)
	
	-- Calculate text metrics
	local font_height = font:getHeight()
	local line_spacing = font_height * 1.2
	local padding = font_height * 0.5
	local nav_height = font_height * 3
	
	-- Draw gradient background
    love.graphics.setColor(0.98, 0.98, 1.0, 0.95)
    love.graphics.rectangle("fill", x, y, width, height/2)
    love.graphics.setColor(0.95, 0.95, 1.0, 0.95)
    love.graphics.rectangle("fill", x, y + height/2, width, height/2)
	
	-- Draw navigation bar
	love.graphics.setColor(0.95, 0.95, 0.95)
	love.graphics.rectangle("fill", x, y, width, nav_height)
	
	-- Draw back/forward buttons
	local button_size = nav_height * 0.6
	local button_padding = (nav_height - button_size) / 2
	love.graphics.setColor(0.95, 0.95, 0.95)
	drawButton(x + button_padding, y + button_padding, button_size, button_size, "←", self.historyIndex > 1)
	drawButton(x + button_padding * 3 + button_size, y + button_padding, button_size, button_size, "→", self.historyIndex < #self.history)

	
	-- Draw URL bar with rounded corners
	love.graphics.setColor(0.95, 0.95, 0.95)
	love.graphics.rectangle("fill", x + nav_height * 1.8, y + button_padding, width - nav_height * 2, button_size, 5, 5)
	love.graphics.setColor(0.9, 0.9, 0.9)
	love.graphics.rectangle("line", x + nav_height * 1.8, y + button_padding, width - nav_height * 2, button_size, 5, 5)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(self.isEditing and self.urlInput or self.currentURL,
		x + nav_height * 1.9, y + button_padding + button_size/4)
	
	-- Draw page content
	local page = self.pages[self.currentURL]
	if page then
		-- Draw title
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(page.title, x + padding, y + nav_height + padding)
		
		-- Draw search box if this is a search page
		if page.isSearch then
			local search_box_height = font_height * 2
			local search_box_y = y + nav_height + padding * 3 + font_height
			drawSearchBox(x + padding, search_box_y, width - padding * 2, search_box_height, 
				self.isSearching and self.searchText or "", "Search securely...", self.isSearching)

				
			-- Draw search button
			if self.searchText and self.searchText ~= "" then
				drawButton(x + width - 100, y + 125, 70, 30, "Search", true)
			end

		end
		
		-- Draw content
		love.graphics.setColor(0, 0, 0)
		local content = type(page.content) == "function" and page.content(self) or page.content
		love.graphics.printf(content, x + 20, y + 180, width - 40)
		
		-- Draw advanced search interface
		if self.currentURL == "advanced_search" then
			-- Draw filter checkboxes
			local filterY = y + 250
			local filters = {"Network Security", "Exploit Development", "Malware Analysis", "Cryptography", "Forensics"}
			for _, filter in ipairs(filters) do
				-- Checkbox
				love.graphics.setColor(1, 1, 1)
				love.graphics.rectangle("fill", x + 30, filterY, 20, 20)
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle("line", x + 30, filterY, 20, 20)
				if self.activeFilters and self.activeFilters[filter] then
					love.graphics.print("✓", x + 33, filterY)
				end
				
				-- Label
				love.graphics.print(filter, x + 60, filterY)
				filterY = filterY + 30
			end
			
			-- Draw time range radio buttons
			local radioY = y + 450
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("Time Range:", x + 30, radioY)
			radioY = radioY + 30
			
			local timeRanges = {"Any time", "Past 24 hours", "Past week", "Past month", "Custom range"}
			for _, range in ipairs(timeRanges) do
				-- Radio button
				love.graphics.setColor(1, 1, 1)
				love.graphics.circle("fill", x + 40, radioY + 10, 10)
				love.graphics.setColor(0, 0, 0)
				love.graphics.circle("line", x + 40, radioY + 10, 10)
				if self.timeRange == range then
					love.graphics.circle("fill", x + 40, radioY + 10, 5)
				end
				
				-- Label
				love.graphics.print(range, x + 60, radioY)
				radioY = radioY + 30
			end

			-- Draw sort options
			local sortY = y + 650
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("Sort By:", x + 30, sortY)
			sortY = sortY + 30
			
			local sortOptions = {"Relevance", "Date", "Popularity"}
			for _, option in ipairs(sortOptions) do
				-- Radio button
				love.graphics.setColor(1, 1, 1)
				love.graphics.circle("fill", x + 40, sortY + 10, 10)
				love.graphics.setColor(0, 0, 0)
				love.graphics.circle("line", x + 40, sortY + 10, 10)
				if self.sortBy == option then
					love.graphics.circle("fill", x + 40, sortY + 10, 5)
				end
				
				-- Label
				love.graphics.print(option, x + 60, sortY)
				sortY = sortY + 30
			end
			
			-- Draw security level options
			local securityY = y + 800
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("Security Level:", x + 30, securityY)
			securityY = securityY + 30
			
			local securityLevels = {"All Results", "Verified Sources Only", "High Security Only"}
			for _, level in ipairs(securityLevels) do
				-- Radio button
				love.graphics.setColor(1, 1, 1)
				love.graphics.circle("fill", x + 40, securityY + 10, 10)
				love.graphics.setColor(0, 0, 0)
				love.graphics.circle("line", x + 40, securityY + 10, 10)
				if self.securityLevel == level then
					love.graphics.circle("fill", x + 40, securityY + 10, 5)
				end
				
				-- Label
				love.graphics.print(level, x + 60, securityY)
				securityY = securityY + 30
			end

			-- Draw advanced search button
			drawButton(x + width - 150, y + height - 60, 130, 40, "Advanced Search", true)

		end
		
		-- Draw enhanced search results
		if self.currentURL == "search_results" then
			local resultY = y + 200
			for _, result in ipairs(self.pages.search_results.results) do
				-- Draw result box with rounded corners
				love.graphics.setColor(0.98, 0.98, 0.98)
				love.graphics.rectangle("fill", x + 20, resultY, width - 40, 120, 8, 8)
				love.graphics.setColor(0.9, 0.9, 0.9)
				love.graphics.rectangle("line", x + 20, resultY, width - 40, 120, 8, 8)
				
				-- Draw title with link icon
				love.graphics.setColor(0.2, 0.4, 0.8)
				drawLinkIcon(x + 30, resultY + 10, 16)
				love.graphics.print(result.title, x + 50, resultY + 10)
				
				-- Draw URL and category with icons
				love.graphics.setColor(0.3, 0.6, 0.3)
				drawLinkIcon(x + 30, resultY + 30, 16)
				love.graphics.print(result.url, x + 50, resultY + 30)
				drawFolderIcon(x + width - 220, resultY + 30, 16)
				love.graphics.print(result.category, x + width - 200, resultY + 30)
				
				-- Draw metadata
				love.graphics.setColor(0.5, 0.5, 0.5)
				local timeAgo = os.time() - result.date
				local timeStr = ""
				if timeAgo < 3600 then
					timeStr = math.floor(timeAgo/60) .. " minutes ago"
				elseif timeAgo < 86400 then
					timeStr = math.floor(timeAgo/3600) .. " hours ago"
				else
					timeStr = math.floor(timeAgo/86400) .. " days ago"
				end
				
				-- Draw badges with icons
				local badgeX = x + 30
				if result.verified then
					love.graphics.setColor(0.2, 0.7, 0.3)
					love.graphics.rectangle("fill", badgeX, resultY + 50, 80, 20, 5, 5)
					love.graphics.setColor(1, 1, 1)
					drawVerifiedIcon(badgeX + 5, resultY + 52, 16)
					love.graphics.print("Verified", badgeX + 25, resultY + 52)
					badgeX = badgeX + 90
				end
				if result.highSecurity then
					love.graphics.setColor(0.7, 0.2, 0.2)
					love.graphics.rectangle("fill", badgeX, resultY + 50, 100, 20, 5, 5)
					love.graphics.setColor(1, 1, 1)
					drawLockIcon(badgeX + 5, resultY + 52, 16)
					love.graphics.print("High Security", badgeX + 25, resultY + 52)
				end
				
				-- Draw metrics
				love.graphics.setColor(0.5, 0.5, 0.5)
				love.graphics.print("Posted: " .. timeStr, x + width - 200, resultY + 50)
				love.graphics.print("Popularity: " .. result.popularity .. "%", x + width - 200, resultY + 70)
				
				-- Draw description
				love.graphics.setColor(0.3, 0.3, 0.3)
				love.graphics.printf(result.description, x + 30, resultY + 80, width - 60)
				
				resultY = resultY + 140
			end
		end
		
		-- Draw chat interface
		if self.currentURL == "securechat" then
			local chats = generateMessages()
			local chatY = y + 250
			
			-- Draw chat list
			for _, chat in ipairs(chats) do
				drawButton(x + 20, chatY, width - 40, 40, chat.channel, self.activeChat == chat.channel)
				chatY = chatY + 50
			end

			
			-- Draw message input if a chat is active
			if self.activeChat then
				drawMessageInput(x + 20, y + height - 60, width - 40, 40,
					self.isTyping and self.messageText or "", "Type a secure message...", self.isTyping)

			end
		end
		
		-- Draw interactive elements
		if page.interactive then
			-- Draw like and comment buttons for posts
			if self.currentURL == "hackernet" then
				local posts = generatePosts()
				local buttonY = y + 400
				for i, post in ipairs(posts) do
					-- Like button
					love.graphics.setColor(0.9, 0.3, 0.3)
					love.graphics.rectangle("fill", x + 20, buttonY, 60, 25)
					love.graphics.setColor(1, 1, 1)
					love.graphics.print("Like", x + 30, buttonY + 5)
					
					-- Comment button
					love.graphics.setColor(0.3, 0.6, 0.9)
					love.graphics.rectangle("fill", x + 90, buttonY, 80, 25)
					love.graphics.setColor(1, 1, 1)
					love.graphics.print("Comment", x + 95, buttonY + 5)
					
					buttonY = buttonY + 100
				end
			end
		end
		
		-- Draw links
		local linkY = y + 400
		for text, url in pairs(page.links) do
			local isHovered = hover.link and 
				x + 20 <= hover.link.x and hover.link.x <= x + 200 and
				linkY <= hover.link.y and hover.link.y <= linkY + 25
			
			love.graphics.setColor(isHovered and {0.3, 0.5, 1.0} or {0.2, 0.4, 0.8})
			if isHovered then
				love.graphics.line(x + 20, linkY + 20, x + 20 + love.graphics.getFont():getWidth(text), linkY + 20)
			end
			love.graphics.print(text, x + 20, linkY)
			linkY = linkY + 30
		end
	end
	
	love.graphics.setFont(default_font)
end

function WebBrowser:mousepressed(x, y, button)
	if button == 1 then
		local page = self.pages[self.currentURL]
		
		-- Handle advanced search interactions
		if self.currentURL == "advanced_search" then
			-- Check filter checkboxes
			local filterY = 250
			local filters = {"Network Security", "Exploit Development", "Malware Analysis", "Cryptography", "Forensics"}
			for _, filter in ipairs(filters) do
				if y >= filterY and y <= filterY + 20 and
				   x >= 30 and x <= 50 then
					self.pages.advanced_search.interactive.toggleFilter(self, filter)
					return true
				end
				filterY = filterY + 30
			end
			
			-- Check time range radio buttons
			local radioY = 480
			local timeRanges = {"Any time", "Past 24 hours", "Past week", "Past month", "Custom range"}
			for _, range in ipairs(timeRanges) do
				if y >= radioY and y <= radioY + 20 and
				   x >= 30 and x <= 50 then
					self.pages.advanced_search.interactive.setTimeRange(self, range)
					return true
				end
				radioY = radioY + 30
			end

			-- Check sort options
			local sortY = 680
			local sortOptions = {"Relevance", "Date", "Popularity"}
			for _, option in ipairs(sortOptions) do
				if y >= sortY and y <= sortY + 20 and
				   x >= 30 and x <= 50 then
					self.pages.advanced_search.interactive.setSortBy(self, option)
					return true
				end
				sortY = sortY + 30
			end
			
			-- Check security levels
			local securityY = 830
			local securityLevels = {"All Results", "Verified Sources Only", "High Security Only"}
			for _, level in ipairs(securityLevels) do
				if y >= securityY and y <= securityY + 20 and
				   x >= 30 and x <= 50 then
					self.pages.advanced_search.interactive.setSecurityLevel(self, level)
					return true
				end
				securityY = securityY + 30
			end

			-- Check advanced search button
			if y >= self.height - 60 and y <= self.height - 20 and
			   x >= self.width - 150 and x <= self.width - 20 then
				-- Perform advanced search with all selected options
				local searchParams = {
					filters = self.activeFilters,
					timeRange = self.timeRange,
					sortBy = self.sortBy,
					securityLevel = self.securityLevel
				}
				if self.searchText and self.searchText ~= "" then
					self:search(self.searchText, searchParams)
				end
				return true
			end
		end
		
		if page and page.isSearch then
			-- Check search box click
			if y >= 120 and y <= 160 and x >= 20 and x <= self.width - 20 then
				self.isSearching = true
				self.searchText = self.searchText or ""
				return true
			end
			
			-- Check search button click
			if self.searchText and self.searchText ~= "" and
			   y >= 125 and y <= 155 and
			   x >= self.width - 100 and x <= self.width - 30 then
				self:search(self.searchText)
				return true
			end
		end
		
		-- Check search result clicks
		if self.currentURL == "search_results" and self.pages.search_results and self.pages.search_results.results then
			local results = self.pages.search_results.results
			local resultY = 250
			for _, result in ipairs(results) do
				if y >= resultY and y <= resultY + 80 and
				   x >= 20 and x <= self.width - 20 then
					-- Navigate to the result URL
					if self.pages[result.url] then
						self:navigate(result.url)
					else
						-- Create a new page for this result
						self.pages[result.url] = {
							title = result.title,
							content = string.format([[
%s
%s

Related Topics:
- Network Security
- Penetration Testing
- Security Tools
]], result.title, result.description),
							links = {
								["Back to Results"] = "search_results",
								["Home"] = "home"
							}
						}
						self:navigate(result.url)
					end
					return true
				end
				resultY = resultY + 140
			end
		end

		if self.currentURL == "securechat" then
			local chats = generateMessages()
			local chatY = 250
			
			-- Check chat channel clicks
			for _, chat in ipairs(chats) do
				if y >= chatY and y <= chatY + 40 and
				   x >= 20 and x <= self.width - 20 then
					self.pages.securechat.interactive.selectChat(self, chat.channel)
					return true
				end
				chatY = chatY + 50
			end
			
			-- Check message input click
			if self.activeChat and
			   y >= self.height - 60 and y <= self.height - 20 and
			   x >= 20 and x <= self.width - 20 then
				self.pages.securechat.interactive.startTyping(self)
				return true
			end
		end

		if page and page.interactive then
			if self.currentURL == "hackernet" then
				local buttonY = 400
				local posts = generatePosts()
				for i, _ in ipairs(posts) do
					-- Check like button
					if y >= buttonY and y <= buttonY + 25 then
						if x >= 20 and x <= 80 then
							page.interactive.like(self, i)
							return true
						elseif x >= 90 and x <= 170 then
							page.interactive.comment(self, i)
							return true
						end
					end
					buttonY = buttonY + 100
				end
			end
		end
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
	if self.currentURL == "securechat" and self.isTyping then
		self.messageText = (self.messageText or "") .. text
		return true
	elseif self.isSearching then
		self.searchText = (self.searchText or "") .. text
		return true
	elseif self.isEditing then
		self.urlInput = self.urlInput .. text
		return true
	end
end

function WebBrowser:keypressed(key)
	if self.currentURL == "securechat" and self.isTyping then
		if key == "return" and self.messageText ~= "" then
			self.pages.securechat.interactive.sendMessage(self, self.messageText)
		elseif key == "escape" then
			self.isTyping = false
			self.messageText = ""
		elseif key == "backspace" then
			self.messageText = self.messageText:sub(1, -2)
		end
		return true
	elseif self.isSearching then
		if key == "return" then
			self:search(self.searchText)
			self.isSearching = false
			self.searchText = nil
		elseif key == "escape" then
			self.isSearching = false
			self.searchText = nil
		elseif key == "backspace" then
			self.searchText = self.searchText:sub(1, -2)
		end
		return true
	elseif self.isEditing then
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

function WebBrowser:search(query, params)
	if not query or query == "" then
		return
	end
	
	local results = generateSearchResults(query)
	
	-- Apply filters if advanced search parameters are provided
	if params then
		local filtered = {}
		for _, result in ipairs(results) do
			local matchesFilters = true
			
			-- Apply category filters
			if params.filters and next(params.filters) then
				local hasMatchingFilter = false
				for filter, active in pairs(params.filters) do
					if active and result.title:lower():find(filter:lower()) then
						hasMatchingFilter = true
						break
					end
				end
				matchesFilters = hasMatchingFilter
			end
			
			-- Apply security level filter
			if params.securityLevel then
				if params.securityLevel == "Verified Sources Only" and not result.verified then
					matchesFilters = false
				elseif params.securityLevel == "High Security Only" and not result.highSecurity then
					matchesFilters = false
				end
			end
			
			if matchesFilters then
				table.insert(filtered, result)
			end
		end
		
		-- Sort results based on selected option
		if params.sortBy then
			table.sort(filtered, function(a, b)
				if params.sortBy == "Relevance" then
					return a.relevance > b.relevance
				elseif params.sortBy == "Date" then
					return a.date > b.date
				elseif params.sortBy == "Popularity" then
					return a.popularity > b.popularity
				end
				return a.relevance > b.relevance
			end)
		end
		
		results = filtered
	end
	
	-- Generate content with search parameters info
	local content = string.format([[
Search Results for: "%s"
=====================

Found %d results in 0.12 seconds
%s
]], query, #results, 
	params and string.format("\nFilters: %s\nSort: %s\nSecurity: %s", 
		next(params.filters or {}) and table.concat(params.filters, ", ") or "None",
		params.sortBy or "Relevance",
		params.securityLevel or "All Results") or "")

	for _, result in ipairs(results) do
		content = content .. string.format([[

[%s]
URL: %s
Relevance: %d%%
───────────────────────────
%s
───────────────────────────

]], result.title, result.url, result.relevance, result.description)
	end
	
	self.pages.search_results = {
		title = string.format('Search Results - "%s"', query),
		content = content,
		links = {
			["New Search"] = "home",
			["Advanced Search"] = "advanced_search",
			["Search History"] = "history"
		},
		results = results
	}
	self:navigate("search_results")
end

function WebBrowser:update(dt)
	-- Add any animation or state updates here if needed
end

return WebBrowser
