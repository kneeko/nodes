Node = class{
	init = function(self, x, y)
		self._type = 'node'
		-- has n parents
		self.position = {x, y, 1}
		self.scale = {1, 1}
		self.size = {12, 12}
		self.origin = {6, 6}

		self.tiles = {}

		self.callbacks = {'inputpressed'}
		self.fudging = 2.5

		getManager():register(self)
	end,

	update = function(self, dt)
		--self.timer = self.timer + dt * 4
		--local dy = math.sin(self.timer) * dt * 50
		--self.position[2] = self.position[2] + dy
	end,

	draw = function(self, ...)
		local position = ...
		local x, y, z = unpack(position)

		lg.setColor(42, 161, 152)
		if self.hit then
			lg.setColor(255, 0, 0)
		end

		lg.circle('fill', x, y, 6)

		lg.setColor(101, 123, 131)
		--lg.print(self.label .. ', #' .. #self.tiles, x, y + 10)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)

		local position = self.position
		-- change this name
		if self:intersecting(identifier, x, y) then
			self.hit = true
			local tiles = self.tiles
			for _,tile in ipairs(tiles) do
				tile:inform()
			end
		end



		-- i need a simple way to check if a point hits an object according to its projection and bound
		-- my projections are hidden behind a viewport identifier so my delegator needs to be aware of this
		-- also mousepressed shouldn't be passed to anything that isnt visible

		-- i actually need some kind of wrapper around mouse callbacks since once it is pressed I will
		-- want to keep track of its position until it is released
		-- so maybe I have inputpressed
		-- inputreleased that uses touch ids etc

		-- maybe a Volume include? what is a good name


	end,
}