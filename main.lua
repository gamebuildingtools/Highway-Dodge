-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here
display.setStatusBar( display.HiddenStatusBar ) -- hide the status bar on iOS devices

local composer = require( "composer" ) -- require in the composer library for scene management
composer.gotoScene("scene_menu") -- move the app to the menu scene