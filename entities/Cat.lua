
Cat = class{
	init = function(self)

		self._type = 'cat'
		self._class = Cat
		
		local x = 0
		local y = 0

		self.position = {x, y, 0.7}
		self.origin = {0.5, 0.5}
		self.size = {1, 1}

		self.unit = 5
		self.base = 20
		self.scale = {0, 0}

		self.velocity = {0, 0, 0}
		self.acceleration = {0, 0, 0}

		self.energy = 4
		self.routes = {}
		self.neighbors = {}

		self.merges = {}

		-- todo
		-- replace fudging with _fudging
		-- or move into overrides
		-- should have a minimum hitbox radius as well
		-- max hitbox as well
		-- maybe a hitbox radius lamba
		self.fudging = 2

		-- higher is more rigid
		self.rigidity = 1.2

		-- higher means faster falloff in acceleration
		self.friction = 20

		self.budable = false
		self.connections = {}

		-- tmp color variation
		local variance = 15
		local color = {
			211 - variance + variance * math.random(),
			54 - variance + variance * math.random(),
			130 - variance + variance * math.random(),
		}

		self.color = color

		-- force parallax level
		self.overrides = {parallax = 1}

		-- pass input callbacks
		self.callbacks = {'inputpressed', 'inputreleased'}
		self.includes = {}

		manager:register(self)
	end,
	update = function(self, dt)

		-- todo
		-- drag events should be keyed by id
		-- there might potentially be multiple inputs per viewport...
		-- drag events should be decoupled
		
		local base = self.base
		local energy = self.energy
		local unit = self.unit
		local scale = self.scale
		local size = math.min(base + unit * energy, 50)
		local sx, sy = unpack(scale)
		scale[1] = sx + (size - sx) * dt * 7
		scale[2] = sy + (size - sy) * dt * 7

		if self.lifetime then
			local cap = 0.2
			self.lifetime = math.min(self.lifetime + dt, cap)
			local lifetime = self.lifetime
			local ratio = math.abs(1 - lifetime / cap)
			local scale = self.scale
			scale[1] = (size) * ratio
			scale[2] = (size) * ratio
			if lifetime == cap then
				self:destroy()
				return
			end
		end

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

			-- use deltas for velocity but blend with previous frame
			-- for more consistent overthrow
			local velocity = self.velocity
			local vx, vy = unpack(velocity)
			velocity[1] = (vx + dx / dt) * 0.5
			velocity[2] = (vy + dy / dt) * 0.5

			-- todo
			-- update the set of collarals in the drag event
			-- which we can get from the parent?


			-- todo
			-- change conversion based on the link strength
			local collateral = {}--self.neighbors
			for _,node in ipairs(collateral) do
				
				local conversion = 0.15

				-- the conversion ratio between the movement of the dragged node
				-- and the nodes it is affecting
				node.position[1] = node.position[1] + dx * conversion
				node.position[2] = node.position[2] + dy * conversion

				-- check if node is gripped or not
				-- and if it should be releaseed

			end

			local graph = self._graph
			local identifier = dragging.identifier
			local parent = self.parent

			-- the tile returned here should
			-- really not just be claimed
			-- it should also be used for merging?

			-- what do i call it when a node is 'over' a tile?
			-- selected?

			-- todo
			-- filter what tiles can get selected
			-- for instance maybe we want to limit expandable tiles
			-- to adjacent positions

			local selected = graph:get_tile(identifier, x, y)

			--[[
			local neighbors = parent.neighbors
			local selected
			for _,neighbor in ipairs(neighbors) do
				if neighbor == queried then
					--selected = queried
				end
			end
			]]--

			if selected then

				-- get the distance from the selected tile center
				local sq = function(n) return math.pow(n, 2) end
				local sqrt = math.sqrt
				local sx, sy = unpack(selected.position)
				local px, py = unpack(parent.position)
				local ox = sx - px
				local oy = sy - py
				local x, y = unpack(position)
				local distance = sqrt(sq(x - ox) + sq(y - oy))

				-- tidy this behaviour up!
				-- if allowed to bud?
				-- budding
				local scale = self.scale

				local boundry = selected.boundry
				local threshold = selected.threshold

				-- todo proper energy management
				local energy = self.energy
				local gripped = self.gripped

				local occupied = selected.cat
				local outside = distance > boundry + threshold
				local inside = distance < boundry
				local affordable = energy > 1
				local budable = self.budable

				-- if we want to be able to continously bud
				-- then remove the occupide requirement
				-- if a node gets dragged across a border and it hasn't budded then
				-- we really want ti to be 'outside'

				-- all of these conditions should be simpler and more distinct

				if (selected ~= self.selected) and (selected ~= parent) then
					-- errr..
					self:connect(selected)
				end


				-- excludes moving into a non-placable area
				if (self.selected) and (self.selected ~= selected) and (self.selected == parent) and (affordable) and (budable) then
					local replica = self:bud()

					-- hand off this drag event to the replica
					local source, identifier, id = dragging.source, dragging.identifier, dragging.id
					replica:drag(source, identifier, id)

					self:drop()
					Route{self, replica}

					budable = false
					selected = nil

				end

				-- this may need to be set for some functions called later one
				self.selected = selected

				if (outside) and (budable) then
					self.budable = false
				end

				if (inside) and (not budable) then
					self.budable = true
				end

				if (outside) and (affordable) and (budable) and (occupied) then

					local replica = self:bud()

					-- hand off this drag event to the replica
					local source, identifier, id = dragging.source, dragging.identifier, dragging.id
					replica:drag(source, identifier, id)


					-- dropping this will clear other routes
					self:drop()
					Route{self, replica}

					-- i'd like to grip this self again
					-- once i have returned to the tile center
					-- so that movement collaterals are restored

				end

				if (inside) and (occupied) and (occupied ~= self) then

					-- we need to migrate to the selected tile
					-- before we merge so that if any nodes
					-- are budded during this drag event
					-- they are not children of the originating parent

					self:migrate(selected)
					self:absorb(occupied)
					--self:connect(selected)

				end


			end

		end

		-- if not at 0, 0 we should snap back to it!

		local rigidity = self.rigidity
		local friction = self.friction

		local acceleration = self.acceleration
		local ax, ay = unpack(acceleration)

		local velocity = self.velocity
		local vx, vy = unpack(velocity)

		acceleration[1] = ax - ax * dt * friction
		acceleration[2] = ay - ay * dt * friction

		velocity[1] = vx + ax * dt
		velocity[2] = vy + ay * dt

		local vx, vy = unpack(velocity)

		velocity[1] = vx - vx * dt * 6 * rigidity
		velocity[2] = vy - vy * dt * 6 * rigidity

		local gripped = self.gripped

		if not gripped then

			local velocity = self.velocity
			local vx, vy = unpack(velocity)

			local position = self.position
			local x, y = unpack(position)

			position[1] = x + vx * dt
			position[2] = y + vy * dt

			-- todo: rename this variable

			local throttle = self.throttle or 0
			self.throttle = math.max(throttle - dt, 0)
			local rate = 10 * rigidity * math.abs(1 - (throttle / 0.15))

			local merging = self.merging

			-- if we're not merging into another node we can recenter on our parent tile
			if not merging then

				-- we're relatively positioned to our parent
				-- so 0,0 centers us

				local position = self.position
				local x, y = unpack(position)
				local dx = -x * rate * dt
				local dy = -y * rate * dt
				position[1] = x + dx
				position[2] = y + dy

				local x, y = unpack(position)


				-- add movement to neighboring tiles?


				local sq = function(n) return math.pow(n, 2) end
				local sqrt = math.sqrt
				local distance = sqrt(sq(x) + sq(y))

				if distance < 1 then
					-- i could instead set a flag to regrip this when
					-- being moved
					--self:grip()
				end

			else
				-- otherwise we'll be moving towards the node that is absorbing us
				-- and then once within a threshold we can disintegrate

				local mx, my = unpack(merging.position)
				position[1] = x + (mx - x) * dt * rate * 0.4
				position[2] = y + (my - y) * dt * rate * 0.4

			end

		end

	end,

	draw = function(self, ...)

		local position, _, _, _, _, identifier = ...
		local x, y = unpack(position)

		local r = self.scale[1] * 0.5

		lg.setColor(0, 0, 0, 20)
		lg.circle('fill', x, y + 4, r, 16)

		local color = self.color
		lg.setColor(color)
		lg.circle('fill', x, y, r, 64)

		lg.setColor(255, 255, 255, 100)
		lg.circle('line', x, y, r, 28)


		lg.setColor(255, 255, 255)
		local s = ("%s%%"):format(self.energy)
		--lg.print(self._key, x, y)

		-- debug drag connection to parent tile
		local dragging = self.dragging
		local parent = self.parent
		local parent_projection = parent.projections[identifier]
		local px, py = unpack(parent_projection)


		local selected = self.selected
		if selected then
			local selected_projection = selected.projections[identifier]
			local sx, sy = unpack(selected_projection)

			lg.setLineWidth(1)
			lg.setColor(180, 255, 180)
			lg.line(x, y, sx, sy)

			lg.setLineWidth(1)


			lg.setColor(255, 180, 180)
			lg.line(x, y, px, py)

		end


		local energy = self.energy
		local font = lg.getFont()
		local w, h = font:getWidth(energy), font:getHeight(energy)
		lg.setColor(255, 255, 255)

		local status = energy
		status = self.energy-- .. ' ' .. tostring(self.budable)
		--status = self._key
		lg.print(status, x - w*0.5, y - h*0.5)

		local status = ''
		for i,merge in ipairs(self.merges) do
			status = status .. tostring(merge) .. ' '
		end


		local neighbors = self.neighbors
		for _,node in ipairs(neighbors) do
			local node_projection = node.projections[identifier]
			local nx, ny = unpack(node_projection)
			lg.setColor(255, 255, 255, 100)
			lg.line(x, y, nx, ny)
		end

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, _, source)

		if self:intersecting(identifier, x, y, 'circle') then

			if tonumber(id) or id == 'l' then
				--self:emit()


				--local replica = self:bud()
				--replica:drag(source, identifier, id)

				self:drag(source, identifier, id)

				-- signal to the scene inputpressed that this initiated an action
				return true

				-- dragging instance?...
				

			end

			-- drag and drop to create a new cat?
			if id == 'r' then
				--self:destroy()
				self:emit()
				return true
			end

		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)
		local dragging = self.dragging
		if dragging then
			self:drop(id)
		end
	end,

	grow = function(self, n)

		--local scale = self.scale
		--local capacity = self.capacity
		--local growth = math.abs(1 - (math.min(scale[1] + n, capacity) / capacity)) * n
		--self.scale[1] = scale[1] + growth
		--self.scale[2] = scale[2] + growth

		local energy = self.energy
		self.energy = energy + n

		self.acceleration[2] = 4000

		if self.energy == 0 then
			self.lifetime = 0
			
			local routes = self.routes
			while #routes > 0 do
				routes[1]:destroy()
			end
		end

	end,

	drag = function(self, source, identifier, id)

		local routes = self.routes
		local x, y = source()
		local dragging = {
			identifier = identifier,
			id = id,
			origin = {x, y},
			source = source,
			cached = {x, y},
		}

		-- todo
		-- key this by the id?
		self:grip()
		self.dragging = dragging

	end,

	drop = function(self, id)

	
		self:release()

		-- this mimics acceleration
		-- when easing back to 0,0
		self.throttle = 0.15

		local velocity = self.velocity
		local vx, vy = unpack(velocity)
		local conversion = 0.2

		local parent = self.parent
		local neighbors = parent.neighbors
		local collateral = {}

		for _,neighbor in ipairs(neighbors) do
			if neighbor.cat then
				table.insert(collateral, neighbor.cat)
			end
		end

		for _,node in ipairs(collateral) do
			--node:release()
			--node.velocity[1] = vx * conversion
			--node.velocity[2] = vy * conversion
		end

		-- if nothing is selected then we should fall back to the parent
		-- for merging with any nodes that are occupying the parent
		local selected = self.selected or parent
		if selected then
			local destination = self:claim(selected)
			self:migrate(destination)
		end

		self:connect(selected)

		self.dragging = nil
		self.selected = nil

		-- todo
		-- behaviour for merging and vanishing
		-- will probably need to go here

	end,

	grip = function(self)
		self.gripped = true
	end,

	release = function(self)
		self.gripped = false
		self.budable = false

	end,

	migrate = function(self, tile)
		if tile then

			local parent = self.parent
			local position = self.position

			local tx, ty = unpack(tile.position)
			local px, py = unpack(parent.position)

			local dx = px - tx
			local dy = py - ty

			position[1] = position[1] + dx
			position[2] = position[2] + dy

			-- set own new parent
			self.parent = tile

		end
	end,

	claim = function(self, selected)


		local parent = self.parent


		-- merge into this this


		-- claiming a tile means
		-- setting the tile's cat to this
		-- handling the merge if there is one to be made

		-- what is this checking?
		-- that this tile is unoccupied

		local occupied = selected.cat-- and selected.cat ~= self
		if occupied == self then

			-- we should do something here to avoid further budding?
			print('selection was parent tile')

		elseif not occupied then

			-- set new parent's reference to self
			selected.cat = self

			-- remove the reference on old parent
			if parent.cat == self then
				parent.cat = nil
			end

			print('moved ' .. self._key .. ' from ' .. parent._key .. ' to ' .. selected._key)

			return selected

		elseif selected then
			-- if occupied
			-- handle the merge
			print(self._key .. ' needs to absorb ' .. occupied._key)
			self:absorb(occupied)

			return selected

		end



		return parent

	end,

	connect = function(self, tile)
		if tile then

			print('connecting')
			--[[
			local parent = self.parent


			-- find new neighbors
			local neighbors = tile.neighbors or parent.neighbors
			local connections = {}
			for _,neighbor in ipairs(neighbors) do
				local node = neighbor.cat
				if node then
					print(self._key .. ' added reference to self in ' .. node._key)
					table.insert(connections, node)
				end
			end

			-- dereference self in previous neighbors listings
			-- this can probably actually be handled by the routes
			-- so really we just need to add and routes that we need
			-- and remove any we don't want
			local previous = self.neighbors
			for _,neighbor in ipairs(previous) do
				for index,reference in ipairs(neighbor.neighbors) do
					if reference == self then
						print(self._key .. ' removed reference to self in ' .. neighbor._key)
						table.remove(neighbor.neighbors, index)
					end
				end
			end


			self.neighbors = connections
			]]--

			local parent = self.parent
			local routes = self.routes

			local required = {}

			local neighbors = tile.neighbors or parent.neighbors
			for _,neighbor in ipairs(neighbors) do
				local node = neighbor.cat
				if node then

					-- we need to check for this route in routes perhaps?
					--local route = Route{self, node}
					required[#required + 1] = node

				end
			end

			-- sever the old routes
			local severing = {}
			for index,node in ipairs(required) do
				for _,route in ipairs(routes) do
					local existing = route:contains(self, node)
					if existing then
						table.remove(required, index)
						print('saved recreating a route')
					else
						route:destroy()
					end
				end
			end

			-- create the required routes
			-- i may want to specify where these are being created from?
			for _,node in ipairs(required) do
				Route{self, node}
			end

			print('connected ' .. self._key)

		end
	end,

	-- absord another node
	absorb = function(self, target)

		-- todo
		-- handle route reflow
		-- move the target into self before destroying
		-- size changes

		-- absorb the energy
		-- there could be a cost here

		local efficiency = 1
		local energy = target.energy

		self:grow(energy * efficiency)

		target:grow(-energy)

		local routes = target.routes
		for _,route in ipairs(routes) do
			local series = route.series
			for index,node in ipairs(series) do
				if node == target then
					series[index] = target
				end
			end
			local from, to = unpack(series)
			route.from = from
			route.to = to
		end

		self.routes = routes

		-- for now just destroy it
		--target:_destroy()

		target:merge(self)


		local parent = self.parent
		local selected = self.selected
		if selected then
			if parent.cat == self then
				parent.cat = nil
			end

			selected.cat = self
		end

		-- i should be able to simulate a "joining" just using velocity and scaling


		-- store this until it's done since we may borrow it again?

	end,

	-- merge self into a node
	merge = function(self, target)

		--self.merging = target

		--local merges = target.merges
		--table.insert(merges, self)


		--self:_destroy()


		local tx, ty = unpack(target.position)
		local acceleration = self.acceleration

		local sq = function(n) return math.pow(n, 2) end
		local sqrt = math.sqrt

		local distance = sqrt(sq(tx) + sq (ty))

		if distance > 30 or true then
			--self.merging = target
		end

		self.merging = target

		-- this should depend on the distance a little bit
		local strength = 400
		acceleration[1] = -tx * strength
		acceleration[2] = -ty * strength

		-- start the popping timer
		-- todo encapsulate this behaviour better
		self.lifetime = 0

		local parent = self.parent
		target:connect(parent)

		-- need a timer

		-- start a timer for disintegrating

		-- in order to animate
		-- some more considerations need to be made
		-- since it introduces a lot of race conditions

		--[[
		self.merging = target
		self:release()
		]]--

		--[[
		local routes = self.routes
		for _,route in ipairs(routes) do
			local series = route.series
			for index,node in ipairs(series) do
				if node == self then
					series[index] = target
				end
			end
			local from, to = unpack(series)
			route.from = from
			route.to = to
		end

		target.routes = routes

		-- for now just destroy it
		self:_destroy()
		--]]--

	end,

	bud = function(self)

		-- todo
		-- make this through the graph
		-- since we'll want to share as much init code as possible there

		-- is there any reasonable way to generalize this?
		-- i could have an attributes table that can just get copied verbatim

		-- check first for something that we are merging?

		local replica
		local merges = self.merges
		if #merges > 0 then
			replica = merges[#merges]
			replica.merging = nil
			table.remove(merges)
		else

			local clone = self._class()

			clone.parent = self.parent
			clone.positioning = self.positioning
			clone.position[1] = self.position[1]
			clone.position[2] = self.position[2]
			clone._graph = self._graph

			replica = clone

		end

		-- todo
		-- deal with energy resource correctly
		local energy = self.energy
		local split = math.floor(energy * 0.5)

		print(energy, split)

		replica.energy = split
		self:grow(-split)

		local selected = self.selected
		local parent = self.parent
		local sx, sy = unpack(selected.position)
		local px, py = unpack(parent.position)
		local ox = sx - px
		local oy = sy - py

		local position = self.position
		local x, y = unpack(position)

		local dx = x - ox
		local dy = y - oy

		-- this should be relative to the selected tile

		local velocity = self.velocity
		local vx, vy = unpack(velocity)
		local amplification = -20
		velocity[1] = vx + dx * amplification
		velocity[2] = vy + dy * amplification

		local acceleration = self.acceleration
		acceleration[2] = 0

		--[[
		local series = {self, clone}

		local route = Route(series)
		for _,node in ipairs(series) do
			local routes = node.routes
			table.insert(routes, route)
		end
		]]--

		-- this replica needs to destroy itself if
		-- it cannot resolve to a different parent

		return replica

	end,

	emit = function(self)

		self:grow(-1)

		-- emit a pulse along the route
		local routes = self.routes or {}
		for _,route in ipairs(routes) do
			route:emit(self)
		end

	end,

	destroy = function(self)

		-- this probably shouldn't 
		-- even be touching the routes
		-- since this will massively complicate what i'm doing... i think?

		local neighbors = self.neighbors
		for _,neighbor in ipairs(neighbors) do
			for index,reference in ipairs(neighbor.neighbors) do
				if reference == self then
					table.remove(neighbor.neighbors, index)
				end
			end
		end

		local parent = self.parent
		if parent then
			if parent.cat == self then
				parent.cat = nil
			end
		end

		self:_destroy()
	end,
}