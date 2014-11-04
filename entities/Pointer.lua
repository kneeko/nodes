--[[
i can use this for colliding with objects in worldspace
]]--

Pointer = class{
	init = function(self)
		self.type = 'input'
		self.positioning = 'fixed'
		self.size = {0, 0}

		-- behaviours to include
		self.callbacks = {'mousepressed'}
		-- register self to object manager
		manager:register(self)
	end,

	update = function(self, dt)

		local x, y = lm.getPosition()
		local position = self.position
		position[1] = x
		position[2] = y
		position[3] = math.huge
		
	end,

	draw = function(self, ...)
		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)

		lg.setColor(200, 100, 100)
		lg.circle('line', x, y, 10)

	end,

	mousepressed = function(self, x, y, button)
	end,
}