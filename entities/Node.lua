Node = class{
	init = function(self, x, y)
	
		self._type = 'node'
		-- has n parents
		self.position = {x, y, 0.9}
		self.scale = {1, 1}
		self.size = {16, 16}
		self.origin = {8, 12}

		self.tiles = {}
		self.ports = {}

		self.overrides = {parallax = 1}
		self.callbacks = {'inputpressed', 'inputreleased'}

		-- listener interfaces with the transmitter for the object manager
		self.includes = {Listener}
		self.fudging = 3

		self.raise = 0

		-- it would be much more elegant if I had a input event manager
		-- that could perform lots of diferent operations (drags, etc...)
		self.sources = {}

		--self.flag = Flag(self)

		self.hit = false
		self.owner = 'none'

		-- this prototype isn't using nodes directly
		--getManager():register(self)

		-- this has to be called after the includes have been merged
		-- or else this method won't yet exist
		--self:listen('owner')

	end,

	update = function(self, dt)

		self.timer[1] = self.timer[1] + dt * 3
		self.timer[2] = self.timer[2] + dt * 2
		local amplitude = 60
		self.position[2] = self.initial[2] + math.cos(self.timer[2]) * amplitude
		self.position[1] = self.initial[1] + math.sin(self.timer[1]) * amplitude

	end,

	draww = function(self, ...)
		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)
		local ox, oy = unpack(origin)

		local raise = self.raise

		y = y - raise

		y = y - 4

		lg.setColor(0, 0, 0, 30)
		lg.circle('fill', x, y + 4, 8)

		if self.hit then
			lg.setColor(255, 149, 0)
		elseif self.down then
			lg.setColor(255, 149, 0, 155)
		else
			lg.setColor(42, 161, 152)
			--lg.setColor(38, 139, 210)
		end

		-- maybe only do this if we are activated?
		if self.hit then
			--y = y - 6
		end

		lg.circle('fill', x, y, 8, 16)

		lg.setColor(255, 255, 255, 130)
		lg.circle('line', x, y, 8, 16)

		lg.setColor(101, 123, 131)
		lg.setColor(255, 255, 255)
		--lg.print(self.label .. ', #' .. #self.tiles, x, y + 10)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)

		local position = self.position

		local hit = self.hit

		if tonumber(id) or id == 'l' then 
		-- change this name
			if self:intersecting(identifier, x, y) then

				--getManager().objects[self._key]:toggle()

				if not self.flag then
					self:toggle()
				end


				-- attempt to start a search



				--client:broadcast(self._key)



				-- add it to the listen table
				-- eventually there will be an elastic pull to active mechanic here
				-- for now, do a hard toggle

				--self.down = true

				--[[
				local sources = self.sources
				sources[id] = {
					start = y,
					source = source,
				}
				]]--

				-- listen to the source and get the deltas for raising the node?
			end
		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		-- just show down state?
		if self.down then
			self.down = false
			-- need to know if this should happen or not
			-- depending on the number of inputs down still
			if self:intersecting(identifier, x, y) then
				--getManager().objects[self._key]:toggle()
				--self:toggle()
				--client:broadcast(self._key)
			end
		end

		local sources = self.sources
		sources[id] = nil

	end,

	toggle = function(self)

		self.hit = not self.hit

		if self.hit then
			self.owner = client.id.hash
			--self._graph:bid(self)
		else
			self.owner = 'none'
		end

		local tiles = self.tiles
		for _,tile in ipairs(tiles) do
			tile:inform()
		end

	end,
}