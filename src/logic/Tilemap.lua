-- Tilemap
--[[

  Implements a hexagonal grid of tiles. Provides location querying, adjacency, and path finding interface.
]]
Tilemap = {}

Tilemap.new = function (init)
  local init = init or {}
  local self = {
    num_rows = init.num_rows or 21, --MUST be Odd for current Adjacency logic
    num_cols = init.num_cols or 42,
    tilesize_x = init.tilesize_x or 84,
    tilesize_y = init.tilesize_y or 73,
    hex_size = init.hex_size or 42, --MUST be half of tilesize_x
    tiles = init.tiles or {},
    terrain_connective_matrix = init.terrain_connective_matrix or {},
    terrain_type_minimap_colors = init.terrain_type_minimap_colors or {
      Ocean = {0, 125, 255},
      Ice = {190, 210, 230},
      Grass = {100, 200, 50},
      Tundra = {150, 200, 170},
      Steppe = {200, 200, 10},
      Desert = {240, 240, 0}
    }
  }

  self.getTileAt = function (position)
    local calc_hex = self.pixel_to_hex(position)
    local calc_idx = calc_hex.col*self.num_rows+math.floor(calc_hex.row)
    if calc_idx <= 0 then
      calc_idx = #self.tiles + calc_idx + 1
    elseif calc_idx >= #self.tiles then
      calc_idx = calc_idx - (#self.tiles + 1)
    end
    return self.tiles[calc_idx]
  end

  self.getIdxAtCoord = function (coord)
    return coord.col * self.num_rows + coord.row
  end

  self.getHexAtCoord = function (coord)
    return self.tiles[getIdxAtCoord(coord)]
  end

  self.getHexAtIdx = function (idx)
    if calc_idx <= 0 then
      idx = #self.tiles + calc_idx + 1
    elseif idx >= #self.tiles then
      idx = (#self.tiles + 1)
    end
    return self.tiles[idx]
  end

  self.getCoordFromIdx = function (idx)
    return {
      col = self.tiles[idx].position.col,
      row = self.tiles[idx].position.row,
      idx = idx
    }
  end

  self.getHexDistance = function(a, b)
    return self.getCubeDistance(self.hex_to_cube(a),self.hex_to_cube(b))
  end

  self.getCylindricalHexDistance = function(a, b)
    if math.abs(a.col - b.col) > self.num_cols/2 then
      --account for going 'the other way'
      local v = self.getHexDistance({row = a.row, col = a.col - self.num_cols + 1}, {row = b.row, col= b.col - self.num_cols + 1})
      return v
    else
      return self.getHexDistance(a,b)
    end
  end

  self.getCubeDistance = function (a, b)
    return (math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)) / 2
  end

  self.pixel_to_hex = function (position)
    if position.x == nil or position.y == nil or position == nil then
      print('oops: no valid pixel provided')
      return {x = nil, y = nil}
    end
    local x = position.x
    local y = position.y
    local size = self.tilesize_x / 2 --TODO: Change to thingy

    local q = x * 2/3 / size
    local r = (-x / 3 + math.sqrt(3)/3 * y) / size

    --return self.hex_round({col = q, row = r})
    return self.cube_to_hex(self.cube_round({x = q, y = -q-r, z = r}))
  end

  self.cube_to_hex = function(h)
    --convert cube to even-q offset
    local col = h.x
    local row = h.z + (h.x + (h.x % 2)) / 2

    return {col = col, row = row}
  end

  self.hex_to_cube = function(h)
    --convert even-q offset to cube
    local x = h.col
    local z = h.row - (h.col + (h.col % 2)) / 2
    local y = -x-z

    return {x = x, y = y, z = z}
  end

  self.hex_round = function (h)
    return self.cube_to_hex(self.cube_round(self.hex_to_cube(h)))
  end

  self.round = function (num)
    return math.floor(num + 0.5)
  end

  self.cube_round = function (h)
    local rx = self.round(h.x)
    local ry = self.round(h.y)
    local rz = self.round(h.z)

    local x_diff = math.abs(rx - h.x)
    local y_diff = math.abs(ry - h.y)
    local z_diff = math.abs(rz - h.z)

    if x_diff > y_diff and x_diff > z_diff then
        rx = -ry-rz
    elseif y_diff > z_diff then
        ry = -rx-rz
    else
        rz = -rx-ry
    end

    return {x = rx, y = ry, z = rz}
  end

  --[[

    A* Methods for lua-astar

  ]]--


  self.getNode = function (this, location)
    -- Here you make sure the requested node is valid (i.e. on the map, not blocked)
    -- if the location is not valid, return nil, otherwise return a new Node object
    local idx = self.getIdxAtCoord(location)
    local move_cost = 1

    if idx < 0 or idx > #self.tiles then
      return nil
    else
      return Node:new(location, move_cost, idx)
    end
  end

  self.locationsAreEqual = function (this, a, b)
    -- Here you check to see if two locations (not nodes) are equivalent
    return a.idx == b.idx
  end

  self.getAdjacentNodes = function (this, curr, goal, domain)
    -- Given a node, return a table containing all adjacent nodes
    local result = {}

    for i, v in pairs(self.terrain_connective_matrix[curr.lid][domain]) do
      local coord = self.getCoordFromIdx(i)
      local consideredN = self:getNode(coord)
      local n = self:_handleNode(consideredN, goal, curr)
      table.insert(result, n)
    end
    return result
  end

  self._handleNode = function (this, considered, goal, parent)
    -- Fetch a Node for the given location and set its parameters
    local dstCol = goal.col
    local dstRow = goal.row
    local idx = self.getIdxAtCoord({col = dstCol, row = dstRow})
    local n = Node:new(considered.location, 0, considered.location.idx)

    if n ~= nil then
      local emCost = math.min(math.min(math.abs(goal.col - self.num_cols - n.location.col),math.abs(n.location.col - self.num_cols - goal.col)),math.abs(goal.col - n.location.col)) + math.abs(goal.row - n.location.row)/2
      n.mCost = 1 + parent.mCost
      n.score = n.mCost + emCost
      n.parent = parent
      n.lid = n.location.idx

      return n
    end

    return nil
  end

  self.astar = AStar(self)
  return self
end
