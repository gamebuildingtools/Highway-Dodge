local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )

local physics = require("physics")
physics.start()
physics.setGravity(0,0)
-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here

-- -------------------------------------------------------------------------------


-- "scene:create()"
function scene:create( event )

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.
    local sceneGroup = self.view

    -- The following variables are known as forward declares. We'll create some for the player, enemy, lanes and establish default values.
    local lanes = {} -- create a table called lanes
    local playerCar -- a variable for the player car
    local laneID = 1 -- a variable for the land id
    local enemyCars = {} -- a table to hold the enemy cars
    local enemyCounter = 1 -- start the enemy counter at 1 to keep track of the enemy cars

    local sendEnemyFrequency = 2500 -- defines how often to send enemy cars
    local tmrToSendCars -- a variable to hold a reference to the timer of sending cars    

    local playerScore = 0 -- start the player score at 0
    local playerScoreText -- an object to hold the score text object

    -- This function will increment the player score by 1. This function is called when the transition for the enemy car is complete and is off screen.
    local function incrementScore()
        playerScore = playerScore + 1 -- add playerScore by 1
        playerScoreText.text = "Score: "..playerScore -- update the on screen text
    end

    -- moveCar will respond to the touch event on the lanes
    local function moveCar(event)
    	if(event.phase == "ended") then 
    		laneID = event.target.id -- grab the lane id which will be 1, 2, or 3
    		transition.to(playerCar, {x=lanes[laneID].x,time=50}) -- move the player car to the appropriate lane
            return true -- to indicate a successful touch event, return true
    	end
    end

    -- sendEnemyCar is where the magic happens. This function will send enemy cars from the top of the screen to the bottom of the screen.
    local function sendEnemyCar()
    	enemyCars[enemyCounter] = display.newImageRect(sceneGroup, "images/enemyCar"..math.random(1,3)..".png", 50, 100) -- create a enemy car and grab a random enemy car image
    	enemyCars[enemyCounter].x = lanes[math.random(1,#lanes)].x -- place the car on a random lane
    		if(math.random(1,2) == 1) then enemyCars[enemyCounter].x = lanes[laneID].x; end -- 50% of the time, place the enemy car on the player car lane. 
    	enemyCars[enemyCounter].y = -125 -- place the enemy off screen at the top
    	enemyCars[enemyCounter]:scale(1,-1) -- rotate the cars so they are facing down
        physics.addBody(enemyCars[enemyCounter]) -- add a physics body to enemy cars
    	enemyCars[enemyCounter].bodyType = "kinematic" -- make the bodies kinematic

    	transition.to(enemyCars[enemyCounter], {y=display.contentHeight+enemyCars[enemyCounter].height+20, time=math.random(2250,3000), onComplete=function(self) display.remove(self); incrementScore(); end}) -- a transition that moves the enemy car towards the bottom of the screen. On completion, the enemy car object is removed from the game.

    	enemyCounter = enemyCounter + 1 -- increase enemy counter by one for tracking
    	if(enemyCounter%2 == 0) then -- every other car, increase the speed of enemy frequency
    		sendEnemyFrequency = sendEnemyFrequency - 200 -- deduct the frequency by 200ms
    		if(sendEnemyFrequency < 800) then sendEnemyFrequency = 800; end -- cap the send enemy frequency to 800
    		timer.cancel(tmrToSendCars) -- cancel the timer of sending cars
    		tmrToSendCars = timer.performWithDelay(sendEnemyFrequency, sendEnemyCar, 0) -- recreate the time to send cars with update frequency
    	end
   	end

    -- Allow the player to return to the menu
    local function onPlayAgainTouch()
        composer.gotoScene("scene_menu", "fade") -- move player to menu
    end

    -- This is the global collision scene. There are several ways to handle collisions and this is only one method. I felt this was the easiest for learning purposes.
    local function onGlobalCollision(event)
        if(event.phase == "began") then -- when the enemy car collides into the player car, this if/then statement will be true        
            
            -- stop the game
            transition.pause()
            timer.cancel(tmrToSendCars)
            physics.pause()
            Runtime:removeEventListener( "collision", onGlobalCollision )

            -- remove event listeners from all lanes
            for i=1,#lanes do                
                lanes[i]:removeEventListener("touch", moveCar)               
            end

            local gameOverBackground = display.newRect(sceneGroup, 0, 0, display.actualContentWidth, display.actualContentHeight) -- display an opaque background graphic for some game over polish
                gameOverBackground.x = display.contentCenterX
                gameOverBackground.y = display.contentCenterY
                gameOverBackground:setFillColor(0)
                gameOverBackground.alpha = 0.5

            -- Create a text object that will display game over text
            local gameOverText = display.newText( sceneGroup, "Game Over!", 100, 200, native.systemFontBold, 36 )
            gameOverText.x = display.contentCenterX
            gameOverText.y = 150
            gameOverText:setFillColor( 1, 1, 1 )    

            -- create a button that allows the player to return to the
            local playAgain = widget.newButton {
                width = 220,
                height = 100,
                defaultFile = "images/btn-blank.png",
                overFile = "images/btn-blank.png",        
                label = "Menu",
                font = system.defaultFontBold,
                fontSize = 32,
                labelColor = { default={ 0, 0, 0 }, over={ 0, 0, 0, 0.5 } },
                onEvent = onPlayAgainTouch
            }
            playAgain.x = display.contentCenterX
            playAgain.y = gameOverText.y + 100
            sceneGroup:insert(playAgain)          
        end
    end

    local background = display.newImageRect(sceneGroup, "images/background.png", 475, 713) -- create the background image object
    	background.x = display.contentCenterX -- place the graphic in the center of the x-axis
    	background.y = display.contentCenterY -- place the graphic in the center of the y-axis

    for i=1,3 do -- loop 3 times to create 3 lanes for our game
	    lanes[i] = display.newImageRect(sceneGroup, "images/lane.png", 79, 713)
	    	lanes[i].x = (display.contentCenterX - 79*2) + (i*80)
	    	lanes[i].y = display.contentCenterY
	    	lanes[i].id = i
	    	lanes[i]:addEventListener("touch", moveCar) -- add an event listener to the lanes that will respond to touch events.
	end

    playerScoreText = display.newText(sceneGroup, "Score: "..playerScore, 0, 0, native.systemFont, 36) -- Create a text object that will display the player score
        playerScoreText.x = display.contentCenterX
        playerScoreText.y = 25

	playerCar = display.newImageRect(sceneGroup, "images/playerCar.png", 50, 100) -- create the player car image object
        playerCar.anchorY = 1 -- set the anchor point to 1 which is the bottom of the graphic
	  	playerCar.x = lanes[1].x -- put the player car on the first lane
	  	playerCar.y = display.contentHeight -- place the car at the bottom of the screen
	  	physics.addBody(playerCar) -- add a physics body to the car
	  	playerCar.bodyType = "dynamic" -- make the car a dynamic body type

	tmrToSendCars = timer.performWithDelay(sendEnemyFrequency, sendEnemyCar, 0) -- start a timer to send cards. A 0 means run forever
    Runtime:addEventListener( "collision", onGlobalCollision ) -- create a global event listener to listen for any collision.

end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.
    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view

    -- Called prior to the removal of scene's view ("sceneGroup").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene