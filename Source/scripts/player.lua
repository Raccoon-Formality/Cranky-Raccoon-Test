local pd <const> = playdate
local gfx <const> = playdate.graphics

class("Player").extends(AnimatedSprite)

function Player:init(x, y, gameManager)
    self.gameManager = gameManager

    -- State Machine
    local playerImageTable = gfx.imagetable.new("images/raccoon-table-16-16")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 2, {tickStep = 4})
    self:addState("run", 2, 3, {tickStep = 4})
    self:addState("jump", 5, 5)
    self:addState("dash", 2, 3, {tickStep = 2})
    self:playAnimation()

    -- Sprite Properties
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.Player)
    self:setTag(TAGS.Player)
    self:setCollideRect(3, 3, 10, 13)

    -- Physics Properties
    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 0.5
    self.maxSpeed = 3
    self.jumpVelocity = -6
    self.drag = 0.2
    self.minimumAirSpeed = 1.0

    self.jumpBufferAmount = 5
    self.jumpBuffer = 0

    self.platformVelocityY = 0.0

    -- Abilities
    self.doubleJumpAbility = false
    self.dashAbility = false

    -- Double Jump
    self.doubleJumpAvailable = true

    -- Dash
    self.dashAvailable = true
    self.dashSpeed = 12
    self.dashMinimumSpeed = 3
    self.dashDrag = 0.8

    -- Player State
    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    self.dead = false
    self.changingLevels = false

    gfx.setDrawOffset(100-self.x, 60-self.y)
    --self.cameraTargetX, self.cameraTargetY = playdate.display.getOffset()
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Hazard or tag == TAGS.Pickup or tag == TAGS.EndLevel then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
    if self.dead then
        return
    end


    --self.cameraTargetX = lerp(self.cameraTargetX, 100-self.x -(self.xVelocity * 16), 0.1)
    --self.cameraTargetY = lerp(self.cameraTargetY,60-self.y, 0.1)
    gfx.setDrawOffset(100-self.x, 60-self.y)

    self:updateAnimation()

    self:updateJumpBuffer()
    self:handleState()
    self:handleMovementAndCollisions()
end

function Player:updateJumpBuffer()
    self.jumpBuffer -= 1
    if self.jumpBuffer <= 0 then
        self.jumpBuffer = 0
    end
    if pd.buttonJustPressed(pd.kButtonA) then
        self.jumpBuffer = self.jumpBufferAmount
    end
end

function Player:playerJumped()
    return self.jumpBuffer > 0
end

function Player:handleState()
    if self.currentState == "idle" then
        self:applyGravitiy()
        self:handleGroundInput()
    elseif self.currentState == "run" then
        self:applyGravitiy()
        self:handleGroundInput()
    elseif self.currentState == "jump" then
        if self.touchingGround then
            self:changeToIdleState()
        end
        self:applyGravitiy()
        --self:applyDrag(self.drag)
        self:handleAirInput()
    elseif self.currentState == "dash" then
        self:applyDrag(self.dashDrag)
        if math.abs(self.xVelocity) <= self.dashMinimumSpeed then
            self:changeToFallState()
        end
    end
end

function Player:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    local died = false

    --print(length)
    for i=1, length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()

        if collisionType == gfx.sprite.kCollisionTypeSlide and collisionTag ~= TAGS.MovingPlatform then
            self:decoupleFromPlatform()
            if collision.normal.y == -1 then
                self.touchingGround = true
                self.doubleJumpAvailable = true
                self.dashAvailable = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end

            if collision.normal.x ~= 0 then
                self.touchingWall = true
            end
        end

        if collisionTag == TAGS.Hazard then
            died = true
        elseif collisionTag == TAGS.Pickup then
            collisionObject:pickUp(self)
            
        elseif collisionTag == TAGS.MovingPlatform then
            
            if collision.normal.y == -1 then
                self.lastMovingPlatform = collisionObject
                collisionObject.playerRelativeX = self.x - collisionObject.x
                collisionObject.playerRelativeY = self.y - collisionObject.y
                collisionObject.player = self
                collisionObject.playerCollided = true

                self.touchingGround = true
                self.doubleJumpAvailable = true
                self.dashAvailable = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end

            if collision.normal.x ~= 0 then
                self.touchingWall = true
                self:decoupleFromPlatform()
            end
        elseif collisionTag == TAGS.EndLevel and not self.changingLevels then
            self.changingLevels = true
            collisionObject:pickUp()
        end
    end

    if self.xVelocity < 0 then 
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

    --[[
    if self.x < 0 then
        self.gameManager:enterRoom("west")
    elseif self.x > 800 then
        self.gameManager:enterRoom("east")
    elseif self.y < 0 then
        self.gameManager:enterRoom("north")
        self.yVelocity = self.jumpVelocity
    elseif self.y > 720 then
        self.gameManager:enterRoom("south")
    end
    ]]--

    if died then
        self:die()
    end
end

function Player:die()
    self.xVelocity = 0
    self.yVelocity = 0
    self.dead = true
    self:setCollisionsEnabled(false)
    pd.timer.performAfterDelay(200, function()
        self:setCollisionsEnabled(true)
        self.dead = false
        self.gameManager:resetPlayer()
    end)
end

function Player:decoupleFromPlatform()
    if self.lastMovingPlatform then
        self.lastMovingPlatform.player = nil
        self.lastMovingPlatform.playerCollided = false
        self.lastMovingPlatform = nil
    end
end

function Player:decoupleFromPlatformWithMomentum()
    if self.lastMovingPlatform then
        self.lastMovingPlatform.player = nil
        self.lastMovingPlatform.playerCollided = false
        self.xVelocity += self.lastMovingPlatform.holdX
        if self.lastMovingPlatform.holdY < 0 then
            self.yVelocity += math.clamp(self.lastMovingPlatform.holdY, -60.0, -6.0)
        elseif self.lastMovingPlatform.holdY > 0 then
            self.yVelocity += self.jumpVelocity
        end
        print(self.yVelocity)
        self.lastMovingPlatform = nil
        self:handleMovementAndCollisions()
    end
end

-- Input Helper Functions
function Player:handleGroundInput()
    if self:playerJumped() then
        self:changeToJumpState()
        self:decoupleFromPlatformWithMomentum()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
        self:decoupleFromPlatform()
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self:decoupleFromPlatform()
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self:decoupleFromPlatform()
        self:changeToRunState("right")
    else
        self:changeToIdleState()
    end
end

function Player:handleAirInput()
    if self:playerJumped() and self.doubleJumpAvailable and self.doubleJumpAbility then
        self.doubleJumpAvailable = false
        self:changeToJumpState()
    elseif pd.buttonJustPressed(pd.kButtonB) and self.dashAvailable and self.dashAbility then
        self:changeToDashState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.maxSpeed
    end
end

-- State Transitions
function Player:changeToIdleState()
    self.xVelocity = 0
    self:changeState("idle")
end

function Player:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.maxSpeed
        self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.maxSpeed
        self.globalFlip = 0
    end
    self:changeState("run")
end

function Player:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self.jumpBuffer = 0
    self:changeState("jump")
end

function Player:changeToFallState()
    self:changeState("jump")
end

function Player:changeToDashState()
    self.dashAvailable = false
    self.yVelocity = 0
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.dashSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.dashSpeed
    else
        if self.globalFlip == 1 then
            self.xVelocity = -self.dashSpeed
        else
            self.xVelocity = self.dashSpeed
        end
    end
    self:changeState("dash")
end

-- Physics Helper Functions
function Player:applyGravitiy()
    self.yVelocity += self.gravity
    if self.touchingGround or self.touchingCeiling then
        self.yVelocity = 0
    end
end

function Player:applyDrag(amount)
    if self.xVelocity > 0 then
        self.xVelocity -= amount
    elseif self.xVelocity < 0 then
        self.xVelocity += amount
    end

    if math.abs(self.xVelocity) < self.minimumAirSpeed or self.touchingWall then
        self.xVelocity = 0
    end
end