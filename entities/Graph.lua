Graph = class{

	init = function(self, step)

		-- should be able to pass a seed to this and get the same map!

		self._type = 'graph'

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

		self.touches = {}

		self.callbacks = {'inputpressed', 'inputreleased'}

		-- parameters for the grid of triangles that will be made
		-- step is the distance between each column, but not row
		local step = 90
		local rows = 20
		local cols = 20
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
				node._graph = self
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

				-- use the identity matrix to find neighbors
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

						local label = ('%s%s%s'):format(node.label, left.label, right.label)

						--if math.random() > 0.15 then

						local tile = Tile(nodes)

						tile._graph = self
						tile.label = label

						table.insert(left.tiles, tile)
						table.insert(right.tiles, tile)
						table.insert(node.tiles, tile)

						tiles[#tiles + 1] = tile

						--end

					end
				end	
			end
		end

		-- iterate through tiles to find tile neighbors
		for _,tile in ipairs(tiles) do

			local nodes = tile.nodes
			local neighbors = {}
			local occurences = {}
			local pool = {}
			for _,node in ipairs(nodes) do
				for _,neighbor in ipairs(node.tiles) do
					local key = neighbor._key
					occurences[key] = occurences[key] and (occurences[key] + 1) or 1
					if occurences[key] >= 2 and (not neighbors[key]) and (key ~= tile._key) then
						neighbors[key] = neighbor
					end
				end
			end

			for _,neighbor in pairs(neighbors) do
				pool[#pool + 1] = neighbor
			end

			tile.neighbors = pool

		end

		local status = ('Created a node graph with %s tiles, %s rows x %s cols.'):format(#tiles, rows, cols)
		print(status)

		self.tiles = tiles
		self.nodes = nodes

		local unit = Unit()
		unit._graph = self

		local unit = Unit()
		unit._graph = self

		getManager():register(self)
	end,

	update = function(self, dt)

		local touches = self.touches

		for id,touch in pairs(touches) do

			local identifier = touch.identifier
			local x, y = touch.source()

			-- todo, spatial hashing
			local tiles = self.tiles
			for _,tile in ipairs(tiles) do
				if tile:intersecting(identifier, x, y) then
					local polygon = tile.polygon
					local inside = polygon:contains(x, y)
					if inside then
						--tile.marked = not tile.marked
					end
				end
			end

		end


	end,

	draw = function(self, ...)
		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)
		local sx, sy = unpack(scale)
		local ox, oy = unpack(origin)
		local kx, ky = unpack(shear)
		local graphic = self.graphic
	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source, project)

		-- send to relevant nodes?
		-- check while inputs are down what tiles it might intersect with? hmm...

		-- i need to be able to unique raycast a tile
		-- without hitting other tiles...

		local touch = {
			source = project,
			identifier = identifier,
		}

		self.touches[id] = touch

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)
		-- send to relevant nodes?
		-- is it possible to have this return keys to hte object manager
		-- and send it to those as well?

		self.touches[id] = nil
	end,

	bid = function(self, tile)

		-- try to start a search
		if tile == self.start or tile == self.goal then
			self.start = nil
			self.goal = nil
			print('reset search')
		end

		if not self.start then
			self.start = tile
			print('set start: ' .. tile.label)

		elseif (not self.goal) and (self.start ~= tile) then
			self.goal = tile
			print('set goal: ' .. tile.label)			
		end


		-- try this search?
		if self.start and self.goal then

			local start = self.start
			local goal = self.goal
			local tiles = self.tiles

			local route = self:path(start, goal)

			if route then
				for _,tile in ipairs(route) do
					tile.marked = true
					for _,node in ipairs(tile.nodes) do
						node.hit = true
					end
				end
			else
				print('unable to path')
			end

			self.start = nil
			self.goal = nil

		end

	end,

	path = function(self, from, to)

		if from and to then
			local route = astar.path(from, to)
			if route then

				return route

			end
			return
		end

	end,

	get_tile = function(self, identifier, x, y)
		local tiles = self.tiles
		for _,tile in ipairs(tiles) do
			if tile:intersecting(identifier, x, y) then
				local polygon = tile.polygon
				local inside = polygon:contains(x, y)
				if inside then
					return tile
				end
			end
		end
	end,
	
}