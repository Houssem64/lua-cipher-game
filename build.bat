Rem This is my build script for making web versions of love2d games using love.js. Feel free to use it / customize it as you see fit.
Rem this line makes it so each line of code doesn't echo into the command window
@echo off
Rem This is the folder that contains all different build versions
Rem The builds folder is defined as "Builds". If it doesn't exist, this will create it.
set buildFolder=Builds
Rem This is the actual folder that you'd zip and distribute
echo Enter the name of this build :
set /p buildName=
echo %buildFolder%
echo %buildName%


if not exist %buildFolder% (
    echo adding build folder %buildFolder%
    mkdir %buildFolder%
)
if exist %buildFolder%\%buildName% (
    echo old build folder already exists
    echo removing old folder
    rmdir /s /q %buildFolder%\%buildName%
)
mkdir %buildFolder%\%buildName%

echo zipping up all files into %buildName%.zip
"C:\Program Files\7-Zip\7z.exe" a %buildFolder%/%buildName%/%buildName%.zip "Engine" "Fonts" "Music" "Sounds" "src" "Textures" "ThirdParty" "conf.lua" "main.lua"

echo renaming zip file to love file
rename %buildFolder%\%buildName%\%buildName%.zip %buildName%.love

@REM Love.js needs you to specify a memory size for the game
@REM https://love2d.org/forums/viewtopic.php?f=12&t=81736&start=160
@REM Need to pick a much bigger size for the game than what is reported by the zip file size
@REM for example, if the file size was 55426989 bytes, you should pick something like 70000000
@REM Otherwise you get a cryptic 'out of bounds' console error in JS
Rem compute the file size first
for %%I in ("%buildFolder%/%buildName%/%buildName%.love") do set numBytes=%%~zI
echo zip file size is %numBytes%

echo Using a value of 70000000 (7 with 7 zeros) for the bytes required to preload game on the web.
echo If you get cryptic failures, try changing this value in webbuild.bat to be much higher than the zip file size.
@REM If you get cryptic errors and it gets stuck at 1/2 when loading the game, try picking a much bigger value.
set numBytes=70000000

echo building with love.js
call npx love.js.cmd -c -m %numBytes% %buildFolder%/%buildName%/%buildName%.love %buildFolder%/%buildName%/%buildName%

echo removing stale love file
del /q %buildFolder%\%buildName%\%buildName%.love

echo creating a zip file for itch.io right under the build folder
cd %buildFolder%
cd %buildName%
"C:\Program Files\7-Zip\7z.exe" a %buildName%.zip "%buildName%\*"
cd ..
cd ..

echo finished build