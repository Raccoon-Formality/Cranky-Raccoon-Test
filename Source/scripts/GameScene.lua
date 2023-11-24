local gfx <const> = playdate.graphics
local ldtk <const> = LDtk

TAGS = {
    Player = 1,
    Hazard = 2,
    Pickup = 3,
    MovingPlatform = 4,
    EndLevel = 5
}

Z_INDEXES = {
    Player = 100,
    Hazard = 20,
    Pickup = 50,
    MovingPlatform = 60,
    EndLevel = 80
}

LEVEL_LIST = {
    {"Level 1","Level_1",true},
    {"Level 2","Level_2",true},
    {"Level 3","Level_3",true},
    {"Level","Level_4",true},
    {"Level 4","Level_0",true},
}
currentLevel = 1

ldtk.load("levels/testWorld.ldtk", false)

class("GameScene").extends()

function GameScene:init(level)
    self.spawnX = 8 * 16
    self.spawnY = 28 * 16
    self:goToLevel(level)
    
    gfx.setBackgroundColor(gfx.kColorBlack)

    
    self.player = Player(self.spawnX, self.spawnY, self)
end

function GameScene:resetPlayer()
    self.player:moveTo(self.spawnX,self.spawnY)
end

function GameScene:enterRoom(direction)
    local level = ldtk.get_neighbours(self.levelName, direction)[1]
    self.playerKeepX = self.player.xVelocity
    self.playerKeepY = self.player.yVelocity
    self:goToLevel(level)
    self.player:add()
    local spawnX, spawnY
    if direction == "north" then 
        spawnX, spawnY = self.player.x, 720
    elseif direction == "south" then
         spawnX, spawnY = self.player.x, 0
    elseif direction == "east" then
        spawnX, spawnY = 0, self.player.y
    elseif direction == "west" then
        spawnX, spawnY = 800, self.player.y
    end
    self.player:moveTo(spawnX, spawnY)
    self.spawnX = spawnX
    self.spawnY = spawnY
    self.player.xVelocity = self.playerKeepX
    self.player.yVelocity = self.playerKeepY
    self.player:handleMovementAndCollisions()
end

function GameScene:goToLevel(level_name)
    gfx.sprite.removeAll()

    self.levelName = level_name
    for layer_name, layer in pairs(ldtk.get_layers(level_name)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(level_name, layer_name)

            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:setCenter(0,0)
            layerSprite:moveTo(0,0)
            layerSprite:setZIndex(layer.zIndex)
            layerSprite:add()

            local emptyTiles = ldtk.get_empty_tileIDs(level_name, "Solid", layer_name)
            if emptyTiles then
                gfx.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end

    for _, entity in ipairs(ldtk.get_entities(level_name)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name
        if entityName == "Spike" then
            Spike(entityX, entityY)
        elseif entityName == "Spikeball" then
            Spikeball(entityX, entityY, entity)
        elseif entityName == "Ability" then
            Ability(entityX, entityY, entity)
        elseif entityName == "MovingPlatforms" then
            MovingPlatform(entityX, entityY, entity)
            --print("test")
        elseif entityName == "EndLevel" then
            EndLevel(entityX, entityY, entity)
            print("fuck")
        elseif entityName == "SpawnPoint" then
            self.spawnX = entityX
            self.spawnY = entityY
        end
    end
end