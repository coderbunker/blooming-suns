--Populator
Populator = {}

function Populator:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Populator:generateTileMapTerrainRandom (map)
  local nr = map.num_rows
  local nc = map.num_cols

  for j = 0, nc - 1 do
    for i = 0, nr - 1 do
      --Randomly Determine terrain
      local terrain_type = "Grass";
      if math.random() > 0.25 then terrain_type = "Grass" else terrain_type = "Wood" end

      --Figure out Array, Pixel, & Grid Coordinates
      local col = j
      local row = i
      local idx = col * nr + row
      local px_x = col * map.tilesize --TODO: Make Pixel location accomodate truly hexagonal tiles
      local px_y = row * map.tilesize --TODO: Make Pixel location accomodate truly hexagonal tiles
      if j % 2 == 0 then px_y = px_y + map.tilesize /2 end

      map.tiles[idx] = Tile:new({
        terrain_type=terrain_type,
        position = {
          x = px_x,
          y = px_y,
          col = col,
          row = row
        },
        owning_map = map,
        idx = idx,
        sprite = SpriteInstance:new({sprite = terrain_type})
      })

      --Figure my neighborhood
      local N = idx - 1
      local S = idx + 1
      local NW, SW
      if j % 2 == 0 then
        NW = idx - nr
        SW = idx - nr + 1
      else
        NW = idx - nr - 1
        SW = idx - nr
      end
      local NE, SE
      if j % 2 == 0 then
        NE = idx + nr
        SE = idx + nr + 1
      else
        NE = idx + nr - 1
        SE = idx + nr
      end
      --Make worlds round
      if j == 0 then
        NW = (nc - 1) * nr + i
        SW = (nc - 1) * nr + 1 + i
      end
      if j == nc -1 then
        NE = i - 1
        SE = i
      end

      --Generate Connectivity (Simple Adjacency)
      map.terrain_connective_matrix[idx] = {air = {}, land = {}, sea = {}}
      if i ~= nr - 1 then
        map.terrain_connective_matrix[idx]['air'][S] = true
      end
      if i ~= 0 then
        map.terrain_connective_matrix[idx]['air'][N] = true
      end
      if i ~= 0 or (i == 0 and j % 2 == 0 )then
        map.terrain_connective_matrix[idx]['air'][NE] = true
        map.terrain_connective_matrix[idx]['air'][NW] = true
      end
      if i ~= nr - 1 or (i == nr - 1 and j % 2 ~= 0) then
        map.terrain_connective_matrix[idx]['air'][SE] = true
        map.terrain_connective_matrix[idx]['air'][SW] = true
      end

    end
  end
end
