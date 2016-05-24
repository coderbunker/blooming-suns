--game classes
require('Tile');
require('Tilemap');
require('PlanetsideTilemapCameraComponent');
require('PlanetsideTilemapView');
require('AlertBoxView');
require('SpriteBank');
require('Sprite');
require('SpriteInstance');
require('Populator');
require('Unit');
require('ViewManager');
require('ViewComponent');
require('View');

--libs
require('lib/astar');
inspect = require('lib/inspect');

function love.load()

  --Load Tileset Sprites
  --TODO: Make hexagonal tilesets
  GlobalSpriteBank = SpriteBank.new()
  GlobalSpriteBank.loadAll()

  --Load View Manager
  GlobalViewManager = ViewManager.new()

  --Create Gamestate
  local defaultTilemap = Tilemap.new()
  local populator = Populator.new()
  populator.generateTileMapTerrainRandom(defaultTilemap)

  --Create Views
  local def_view = PlanetsideTilemapView.new({
    model = defaultTilemap,
    rect = {x = 0, y = 0, w = love.graphics.getWidth(), h = love.graphics.getHeight()}
  })
  GlobalViewManager.push(def_view)

  --DEBUG: REMOVE
  local path = def_view.model.astar:findPath({col = 0, row = 4, idx = 4}, {col = 4, row = 6, idx = 90})
  print("###path###")
  print(inspect(path.nodes,{depth=2}))
  print("###/PATH###")
end

function love.update(dt)
  --Debug mouse-to-hex output
  if love.keyboard.isDown('f') then
    print(inspect(GlobalViewManager.views[GlobalViewManager.activeView].camera.target.pixel_to_hex({x = love.mouse.getX(), y = love.mouse.getY()})))
  end
  if not GLOBAL_PAUSE then
    GlobalViewManager.update(dt)
  end
end

function love.draw()
  if not GLOBAL_PAUSE then
    GlobalViewManager.draw()
  end
end

function love.mousepressed(x, y, button)
  GlobalViewManager.onMousePressed(x,y,button)
end

function love.mousereleased(x, y, button)
  GlobalViewManager.onMouseReleased(x,y,button)
end

function love.keypressed(key)
  GlobalViewManager.onKeyPressed(key)
end

function love.focus(f)
  if not f then
    print("LOST FOCUS")
    GLOBAL_PAUSE = true
  else
    print("GAINED FOCUS")
    GLOBAL_PAUSE = false
  end
end

function love.quit()
  print("Thanks for playing! Come back soon!")
end
