return {
  
    -- basic settings:
    name = 'SuperGame', -- name of the game for your executable
    developer = 'CoolDev', -- dev name used in metadata of the file
    output = 'dist', -- output location for your game, defaults to $SAVE_DIRECTORY
    version = '1.1a', -- 'version' of your game, used to name the folder in output
    love = '11.5', -- version of LÖVE to use, must match github releases
    ignore = {'dist', 'ignoreme.txt'}, -- folders/files to ignore in your project
    icon = 'resources/icon.png', -- 256x256px PNG icon for game, will be converted for you
    
    -- optional settings:
    use32bit = false, -- set true to build windows 32-bit as well as 64-bit
    identifier = 'com.love.supergame', -- macos team identifier, defaults to game.developer.name
    libs = { -- files to place in output directly rather than fuse
      windows = {'resources/plugin.dll'}, -- can specify per platform or "all"
      all = {'resources/license.txt'}
    },
    hooks = { -- hooks to run commands via os.execute before or after building
      before_build = 'resources/preprocess.sh',
      after_build = 'resources/postprocess.sh'
    },
    platforms = {'linux'} -- set if you only want to build for a specific platform
    
  }