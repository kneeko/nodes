DragEvent = class{
	init = function(self, x, y, id, pressure, source)

		local position = {x, y, pressure}
		local moved = {0, 0, 0}

		self.id = id
		self.position = position
		self.source = source
		self.moved = moved

	end,

	update = function(self, dt)

		local source = self.source
		local x, y, p = source()

		local position = self.position
		local px, py, pp = unpack(position)

		-- offset from start?
		local dx = x - px
		local dy = y - py
		local dp = p - pp

		-- get the delta since last move
		local moved = self.moved

		moved[1] = dx
		moved[2] = dy
		moved[3] = dp

		position[1] = x
		position[2] = y
		position[3] = p

	end,

	get = function(self)

		local moved = self.moved
		return unpack(moved)

	end,

	cancel = function(self)
	end,

	complete = function(self)
	end,
}