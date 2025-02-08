-- conf.lua
function love.conf(t)
   t.window.title = "Cipher Protocol"
   t.window.width = 1920
   t.window.height = 1080
   t.window.resizable = true
   t.window.vsync = true
   t.window.minwidth = 800
   t.window.minheight = 600
   t.window.fullscreen = false
   t.window.usedpiscale = false
   -- Enable all modules
   t.modules.audio = true
   t.modules.data = true
   t.modules.event = true
   t.modules.font = true
   t.modules.graphics = true
   t.modules.image = true
   t.modules.joystick = true
   t.modules.keyboard = true
   t.modules.math = true
   t.modules.mouse = true
   t.modules.physics = true
   t.modules.sound = true
   t.modules.system = true
   t.modules.thread = true
   t.modules.timer = true
   t.modules.window = true
end