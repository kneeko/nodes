-- implement movement for units


Unit = class{

	init = function(self)

		self._type = 'unit'

		local x = 200 + 400 * math.random()
		local y = 100 + 400 * math.random()

		self.position = {x, y, 0.8}
		self.size = {30, 30}
		self.origin = {15, 15}
		self.scale = {1, 1}

		self.fudging = 2

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

		local path = self.path
		local bezier = self.bezier

		if bezier then
			local timer = self.timer
			local duration = self.duration
			self.timer = math.min(timer + dt, duration)

			local t = easing.inOutQuad(self.timer / duration, 0, 1, 1)

			local x, y = bezier:evaluate(t)

			position[1] = x
			position[2] = y

			if t == 1 then
				self.bezier = nil
				self.rally:set(0, 0)
			end


		end

	end,

	draw = function(self, ...)

		local position = ...
		local x, y = unpack(position)

		lg.setColor(0, 0, 0, 20)
		lg.circle('fill', x, y + 4, 15, 16)

		lg.setColor(211, 54, 130)
		lg.circle('fill', x, y, 15, 16)

		lg.setColor(255, 255, 255, 150)
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
			rally.identifier = identifier

			self.rallying = true



			-- set a flag so that we can move once this drag event is complete
			
		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		local drags = self.drags
		drags:remove(x, y, id, pressure)

		if self.rallying then

			local path = self:calculate(identifier, self.rally)
			self:traverse(path)

			self.rallying = false
			self.rally:set(0, 0)
			self.rally.identifier = nil

		end


		-- if the rally was being set
		-- we can now move towards it
		-- however the rally is not in world space, it is relatively positioned
		-- so as we move towards it we need to "reel" it in

	end,

	traverse = function(self, path)
		if path then

				local fx, fy = unpack(self.position)
				local rx, ry = unpack(self.rally.position)
				local tx = fx + rx
				local ty = fy + ry

				-- replace the first and last tile with dummies for actual start and end point
				local from = {position = {fx, fy}}
				local to = {position = {tx, ty}}

				-- get rid of the first and last ile
				path[#path] = nil
				path[1] = from
				path[#path + 1] = to
				local vertices = {}

				for _,tile in ipairs(path) do
					local x, y = unpack(tile.position)
					table.insert(vertices, x)
					table.insert(vertices, y)
				end

				self.path = path

				-- make a bezier curve of the path?
				local bezier = love.math.newBezierCurve(vertices)
				self.bezier = bezier

				self.duration = #path * 0.1
				self.timer = 0

			end
	end,

	calculate = function(self, identifier, to)

		local graph = self._graph

		local px, py = unpack(self.position)
		local rx, ry = unpack(to.position)

		local from = graph:get_tile(identifier, px, py)
		local to = graph:get_tile(identifier, px + rx, py + ry)

		local path = graph:path(from, to)

		return path

	end,

}
