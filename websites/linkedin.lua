local LinkedInSite = {}

function LinkedInSite:new()
    local obj = {
        width = 0,
        height = 0,
        currentPage = "",
        colors = {
            background = {0.95, 0.95, 0.95},
            navbar = {1, 1, 1},
            text = {0.2, 0.2, 0.2},
            accent = {0, 0.65, 0.95},
            border = {0.85, 0.85, 0.85},
            button = {0, 0.55, 0.85}
        },
        navHeight = 60,
        sections = {
            profile = {
                {
                    title = "Software Engineer at Tech Corp",
                    description = "Leading development of web applications",
                    company = "Tech Corp",
                    date = "2020 - Present"
                },
                {
                    title = "Full Stack Developer",
                    description = "Developed scalable backend services",
                    company = "StartUp Inc",
                    date = "2018 - 2020"
                }
            },
            jobs = {
                {
                    title = "Senior Software Engineer",
                    company = "Tech Corp",
                    location = "San Francisco, CA",
                    salary = "$150,000 - $200,000/year",
                    description = "Join our team building next-gen cloud solutions"
                },
                {
                    title = "Full Stack Developer",
                    company = "Tech Corp",
                    location = "Remote",
                    salary = "$120,000 - $160,000/year",
                    description = "Help build scalable web applications"
                }
            }
        }
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function LinkedInSite:draw(x, y, width, height)
    self.width = width
    self.height = height

    -- Draw background
    love.graphics.setColor(unpack(self.colors.background))
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw navbar
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x, y, width, self.navHeight)
    love.graphics.setColor(unpack(self.colors.accent))
    love.graphics.print("LinkedIn", x + 20, y + 20)

    -- Draw page content based on current page
    if self.currentPage:match("^profile") then
        self:drawProfile(x, y + self.navHeight, width, height - self.navHeight)
    elseif self.currentPage:match("^jobs") then
        self:drawJobs(x, y + self.navHeight, width, height - self.navHeight)
    elseif self.currentPage:match("^company") then
        self:drawCompany(x, y + self.navHeight, width, height - self.navHeight)
    else
        self:drawProfile(x, y + self.navHeight, width, height - self.navHeight)
    end
end

function LinkedInSite:drawProfile(x, y, width, height)
    -- Profile header
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x + 20, y + 20, width - 40, 200)
    love.graphics.setColor(unpack(self.colors.text))
    love.graphics.print("John Doe", x + 40, y + 40)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Software Engineer | Full Stack Developer", x + 40, y + 70)
    love.graphics.print("San Francisco Bay Area", x + 40, y + 90)

    -- Experience section
    local sectionY = y + 240
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x + 20, sectionY, width - 40, 300)
    love.graphics.setColor(unpack(self.colors.text))
    love.graphics.print("Experience", x + 40, sectionY + 20)

    local itemY = sectionY + 60
    for _, section in ipairs(self.sections.profile) do
        love.graphics.setColor(unpack(self.colors.text))
        love.graphics.print(section.title, x + 60, itemY)
        love.graphics.print(section.company, x + 60, itemY + 25)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(section.date, x + 60, itemY + 45)
        love.graphics.print(section.description, x + 60, itemY + 65)
        itemY = itemY + 100
    end
end

function LinkedInSite:drawJobs(x, y, width, height)
    -- Jobs header
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x + 20, y + 20, width - 40, 80)
    love.graphics.setColor(unpack(self.colors.text))
    love.graphics.print("Jobs at Tech Corp", x + 40, y + 40)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("2 open positions", x + 40, y + 60)

    -- Job listings
    local itemY = y + 120
    for _, job in ipairs(self.sections.jobs) do
        love.graphics.setColor(unpack(self.colors.navbar))
        love.graphics.rectangle("fill", x + 20, itemY, width - 40, 150)
        
        love.graphics.setColor(unpack(self.colors.text))
        love.graphics.print(job.title, x + 40, itemY + 20)
        love.graphics.print(job.company, x + 40, itemY + 45)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(job.location, x + 40, itemY + 70)
        love.graphics.print(job.salary, x + 40, itemY + 90)
        love.graphics.print(job.description, x + 40, itemY + 110)
        
        itemY = itemY + 170
    end
end

function LinkedInSite:drawCompany(x, y, width, height)
    -- Company header
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x + 20, y + 20, width - 40, 200)
    love.graphics.setColor(unpack(self.colors.text))
    love.graphics.print("Tech Corp", x + 40, y + 40)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Technology • San Francisco, CA", x + 40, y + 70)
    love.graphics.print("10,000+ employees", x + 40, y + 90)
    love.graphics.print("Leading provider of cloud solutions and enterprise software", x + 40, y + 120)

    -- Company stats
    local statsY = y + 240
    love.graphics.setColor(unpack(self.colors.navbar))
    love.graphics.rectangle("fill", x + 20, statsY, width - 40, 100)
    love.graphics.setColor(unpack(self.colors.text))
    love.graphics.print("Company Stats", x + 40, statsY + 20)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("• Founded: 2010", x + 40, statsY + 50)
    love.graphics.print("• Revenue: $1B+", x + 200, statsY + 50)
    love.graphics.print("• Industry: Technology", x + 400, statsY + 50)
end

return LinkedInSite