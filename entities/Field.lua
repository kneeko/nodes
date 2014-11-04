Field = class{
	init = function(self, step)
		self.type = 'field'

		local x = 50
		local y = 50
		local z = 1
		local w = 0
		local h = 0
		local scale = 1

		self.position = {x, y, z}
		self.size = {w, h}
		self.scale = {scale, scale}
		self.origin = {0, 0}
		self.angle = 0
		self.timer = 0

		-- parameters for the grid of triangles that will be made
		-- step is the distance between each column, but not row
		local step = 220
		local rows = 3 
		local cols = 4
		local convex = true

		-- we only need to calculate these once
		-- we can modulate the shape of the triangles
		-- by modifying the coefficients
		-- if it is possibly to modify these in realtime it could make for some cool effects
		local pi = math.pi
		local cos = math.cos(pi/3)
		local sin = math.sin(pi/3)

		-- make a grid of staggered nodes that form equillateral triangles
		local nodes = {}
		for r = 0, rows do

			-- fill in the ends
			local extend = (r % 2 == 0) and (-1) or (0)
			local indent = (r % 2 ~= 0 and convex) and (0) or (1)

			for c = 0, cols + extend do

				-- stagger on even rows
				local stagger = (r % 2 == 0) and (step * cos) or (0)

				-- determine the position
				local nx = x + stagger + (step) * c
				local ny = y + (step * sin) * r

				-- make the node
				local node = Node(nx, ny)

				node.label = '(' .. r ..' , ' .. c ..')'

				-- store the node in a two dimensional array
				nodes[r] = nodes[r] or {}
				nodes[r][c] = node

			end
		end

		local tiles = {}

		-- possible_neighbors identity matrix for finding neighbors
		-- this is valid so long as I use the same row/col mapping
		local possible_neighbors = {
			{-1, -1},
			{-1,  0},
			{ 0, -1},
			{ 0,  1},
			{ 1, -1},
			{ 1,  0},
		}

		local possible_tiles = {
			{1, 2},
			{5, 6},
		}

		-- iterate through the nodes to specify their neighbors
		for r,row in pairs(nodes) do
			for c,node in pairs(row) do

				-- the column lookup needs to be shifted if the row is even
				local even = r % 2 == 0
				local shift = even and 1 or 0

				-- use the identity matric to find neighbors
				local neighbors = {}
				local map = {}
				for i,n in ipairs(possible_neighbors) do

					-- dc and dr are the row and column offsets relative to the parent node at (r, c)
					local dc, dr = unpack(n)
					local nr = r + dc
					local nc = c + dr + shift * math.abs(dc)

					-- if the neighbor exists, add it to neighbors
					-- keep track of which ones are valid since we need that for
					-- creating the tiles
					local neighbor = nodes[nr] and nodes[nr][nc] or nil
					if neighbor then
						local index = #neighbors + 1
						neighbors[index] = neighbor
						map[i] = index
					end

				end

				-- store the discovered neighbors to the node
				node.neighbors = neighbors

				-- use the identity matrix to find and add tiles
				for _,pair in ipairs(possible_tiles) do
					local left_index = map[pair[1]]
					local right_index = map[pair[2]]
					if left_index and right_index then

						local left = neighbors[left_index]
						local right = neighbors[right_index]

						local nodes = {
							node,
							left,
							right,
						}
						local tile = Tile(nodes)
						tiles[#tiles + 1] = tile

						table.insert(left.tiles, tile)
						table.insert(right.tiles, tile)
						table.insert(node.tiles, tile)

					end
				end

				
			end
		end

		print(#tiles .. ' tiles, ' .. rows .. ' rows by ' .. cols .. ' cols')

		-- generate tiles now that the neighbors are known

		getManager():register(self)
	end,

	update = function(self, dt)
	end,

	draw = function(self, ...)
		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)
		local sx, sy = unpack(scale)
		local ox, oy = unpack(origin)
		local kx, ky = unpack(shear)
		local graphic = self.graphic


	end,
}