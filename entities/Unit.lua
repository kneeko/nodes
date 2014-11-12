-- implement movement for units


Unit = class{

	init = function(self)

		self._type = 'unit'

		self.position = {250, 250, 0.9}
		self.size = {30, 30}
		self.origin = {15, 15}
		self.scale = {1, 1}

		self.overrides = {parallax = 1}
		self.callbacks = {'inputpressed', 'inputreleased'}

		self.drags = DragManager()
		self.rally = Rally(self)

		getManager():register(self)

	end,

	update = function(self, dt)

		-- keep track of sources
		-- maybe have a class to deal with this?...
		-- drag mananger get sum of active drags?

		local rally = self.rally
		local drags = self.drags
		drags:update()

		local dx, dy = drags:delta()
		if dx and dy then
			rally:move(dx, dy)
		end

		local rx, ry = unpack(rally.position)
		local position = self.position

		if not self.rallying then
			local x, y = unpack(position)
			local dx = rx * dt * 4
			local dy = ry * dt * 4
			position[1] = x + dx
			position[2] = y + dy
			rally.position[1] = rx - dx
			rally.position[2] = ry - dy
		end

	end,

	draw = function(self, ...)

		local position = ...
		local x, y = unpack(position)

		lg.setColor(130, 170, 120)
		lg.circle('fill', x, y, 15, 16)

		lg.setColor(255, 255, 255)
		lg.circle('line', x, y, 15, 16)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source, project)

		if self:intersecting(identifier, x, y) then

			-- start moving the rally point
			local drags = self.drags

			-- should this have a callback?
			drags:add(x, y, id, pressure, project)

			local rally = self.rally
			rally:set(0, 0)

			self.rallying = true

			-- set a flag so that we can move once this drag event is complete
			
		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		local drags = self.drags
		drags:remove(x, y, id, pressure)

		self.rallying = false

		-- if the rally was being set
		-- we can now move towards it
		-- however the rally is not in world space, it is relatively positioned
		-- so as we move towards it we need to "reel" it in

	end,

}
