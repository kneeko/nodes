Rally = class{
	init = function(self, parent)

		self.position = {0, 0, 0.9}
		self.positioning = 'relative'

		self.overrides = {parallax = 1}
		self.parent = parent

		getManager():register(self)
	end,

	update = function(self, dt)
	end,

	set = function(self, x, y)
		local position = self.position
		position[1] = x
		position[2] = y
	end,

	move = function(self, dx, dy)
		local position = self.position
		position[1] = dx and position[1] + dx or position[1]
		position[2] = dy and position[2] + dy or position[2]
	end,

	draw = function(self, ...)
	
		local position = ...
		local x, y = unpack(position)
		lg.setColor(255, 0, 0)
		lg.circle('line', x, y, 10)

		local parent = self.parent
		local px, py = unpack(parent.position)
		lg.line(x, y, px, py)

	end,

	-- could this have a method where it is passed the parent position
	-- and moves towards it?

	-- this could contain a method to find suitable checkpoints for navigating the meshes?
	-- boy this gets incredibly complicated 
	--[[

	get traversable nodes
	-- selecting a node
	-- selecting a unit
	-- a port is open when two nodes are both accessible
		-- can I do a* on ports?

	-- ports can be owned by multiple tiles
	-- but it is certainly easy to generate the ports when refreshing the tile
	-- including their actual worldspace position!

	]]--

}