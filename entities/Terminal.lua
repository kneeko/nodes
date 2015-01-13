-- paths have directionality
-- a path cannot belong to a terminal really...
-- a terminal is just used to direct and place nodes
-- and a well is used to emit things from a node
-- a node could have directionality? this kind of depends on the type of behaviour i want it to have
-- can a node have multiple nodes in its 'from and to'? this allows me to define explicit flow direction

-- maybe when dragging into an existing part of the path
-- show some kind of feedback fading out the severed portion
-- and only disconnect it when passing through the center to another tile

-- this just places stuff


Terminal = class{
	init = function(self)

		self._type = 'terminal'

		local position = {0, 0, 0.6}
		local scale = {1, 1}
		local size = {40, 40}
		local origin = {20, 20}
		local positioning = 'relative'

		self._debug = true
		self.fudging = 1

		-- todo
		-- convert this to a Route object
		local path = {}
		self.path = path

		self.position = position
		self.scale = scale
		self.origin = origin
		self.size = size
		self.positioning = positioning

		self.callbacks = {'inputpressed', 'inputreleased'}
		self.overrides = {parallax = 1}

		manager:register(self)

	end,

	update = function(self, dt)

		local dragging = self.dragging
		if dragging then

			local ox, oy = unpack(dragging.origin)
			local cx, cy = unpack(dragging.cached)
			local x, y = dragging.source()

			local dx = x - cx
			local dy = y - cy

			local position = self.position
			position[1] = position[1] + dx
			position[2] = position[2] + dy

			dragging.cached[1] = x
			dragging.cached[2] = y

			local identifier = dragging.identifier
			local graph = self._graph

			-- use the actual object position rather than the tough position
			local projections = self.projections
			local projection = projections[identifier] or {x, y}
			local px, py = unpack(projection)
			local selected = graph:get_tile(identifier, px, py)

			if selected and selected ~= self.selected then
				self:migrate(selected)
				self:connect(selected)
			end

			self.selected = selected

		end

		if not dragging then
			local position = self.position
			local x, y = unpack(position)
			local snappiness = 30
			position[1] = x - x * dt * snappiness
			position[2] = y - y * dt * snappiness
		end

	end,

	drag = function(self, source, identifier, id)

		local x, y = source()
		local dragging = {
			identifier = identifier,
			id = id,
			origin = {x, y},
			source = source,
			cached = {x, y},
		}

		-- todo
		-- key this by id
		self.dragging = dragging

	end,

	drop = function(self)

		self.dragging = nil

		local selected = self.selected

		self:migrate(selected)

		self.selected = nil

		-- maybe drop into a new tile? hmm

	end,

	connect = function(self, to)
		local path = self.path
		if to then

			-- check if we are to undo anything?
			-- we really need to use this method on everything we add to the path
			-- how do we resolve replacing stuff?

			local graph = self._graph
			local from = path[#path] and path[#path].parent
			local reverting

			-- revert if this node exists in the path already
			-- todo
			-- consider other ways of resolving going back over the same route
			-- this is pretty punishing and provides no undo mechanism
			if #path > 0 then
				local index
				for i,node in ipairs(path) do
					if node.parent == to then
						index = i
						break
					end
				end
				if index then

					-- only sever the path?
					--[[
					local node = path[index + 1]
					if node then
						node:destroy()
						path[index + 1] = nil
					end
					]]--

					for i = index + 1, #path do
						-- remove all the nodes after the match
						local node = path[i]
						node:destroy()
						path[i] = nil
					end
					reverting = true
				end
			end

			if not reverting then

				-- todo
				-- should this pathfinding create paths around existing routes to this terminal?
				-- i'd need to modify the neighbors function in astar, or better yet decouple it
				-- entirely

				local route = graph:path(from, to)
				if route and #route > 2 then
					for index,entry in ipairs(route) do
						if entry ~= from then
							self:connect(entry)
						end
					end
				else
					
					-- hook this node up to the previous?
					local node = Node()
					node.parent = to

					to.node = node

					node._graph = self._graph

					-- set the previous node
					local previous = path[#path]
					if previous then
						-- add this node to the previous node's destinations
						-- so that a signal can traverse it
						previous:add(node)
						node:add(previous)
					end

					path[#path + 1] = node

				end
			end


		end

	end,

	migrate = function(self, destination)
		local parent = self.parent
		if destination and destination ~= parent then

			local position = self.position

			local tx, ty = unpack(destination.position)
			local px, py = unpack(parent.position)

			local dx = px - tx
			local dy = py - ty

			position[1] = position[1] + dx
			position[2] = position[2] + dy

			destination.terminal = self
			parent.terminal = nil
			self.parent = destination

		end
	end,

	draw = function(self, identifier, ...)

		local projection = ...

		local x, y = unpack(projection)

		

		local selected = self.selected
		if selected then
			local sx, sy = unpack(selected.projections[identifier])
			lg.setColor(255, 255, 255)
			lg.line(x, y, sx, sy)
		end

		local path = self.path
		local vertices = {}
		for _,node in ipairs(path) do
			local node_projection = node.projections[identifier]
			if node_projection then
				local nx, ny = unpack(node_projection)
				vertices[#vertices + 1] = nx
				vertices[#vertices + 1] = ny
			else
				print('could not find node projection for ' .. tostring(node._key))
			end
		end

		--vertices = smooth(vertices, 40)

		local map = {}
		for index,node in ipairs(path) do
			local nx, ny = unpack(node.projections[identifier])
			local oy = map[node._key] and map[node._key] * 15 or 0
			lg.print(node._key, nx, ny + oy)
			map[node._key] = map[node._key] and map[node._key] + 1 or 1
		end

		if #vertices >= 4 then
			lg.setColor(255, 255, 255)
			lg.setLineWidth(2)
			--lg.line(vertices)
			lg.setLineWidth(1)
		end

		local font = lg.getFont()
		local string = 'T' .. self._key
		local w, h = font:getWidth(string), font:getHeight(string)
		lg.setColor(255, 255, 255)
		lg.print(string, x - w*0.5, y - h*0.5)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, _, source)
		local hit = self:intersecting(identifier, x, y, 'circle')
		if hit and id == 'l' then
			self:drag(source, identifier, id)
			return true
		end
	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		local dragging = self.dragging
		if dragging then
			if dragging.id == id then
				self:drop()
			end
		end

	end,
}