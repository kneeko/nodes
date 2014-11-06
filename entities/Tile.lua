Tile = class{
	init = function(self, nodes)
		self._type = 'tile'
		-- is passed references to nodes for its children
		-- uses their position and order to draw the fill

		self.nodes = nodes

		self:refresh()


		getManager():register(self)

	end,

	update = function(self, dt)
	end,

	draw = function(self, ...)
		-- i need to get the position of each node as projected, not just their own position
		local position = ...
		local x, y = unpack(position)

		local nodes = self.nodes
		local points = {}
		local inset = 0
		for i = 1, #nodes do
			local position = nodes[i].position
			local nx = position[1]
			local ny = position[2]
			points[#points + 1] = x*inset + nx*(1 - inset)
			points[#points + 1] = y*inset + ny*(1 - inset)
		end

		lg.setColor(0, 43, 54, 80)

		if self.claimed then
			lg.setColor(20, 93, 54, 180)
		end			

		if self.marked then
			lg.setColor(190, 80, 10, 160)
		end

		lg.polygon('fill', points)
		lg.setColor(255, 255, 255, 100)
		lg.polygon('line', points)

		lg.setColor(101, 123, 131)

	end,

	inform = function(self)
		local nodes = self.nodes
		local switch = true
		for _,node in ipairs(nodes) do
			switch = switch and node.hit
		end

		if switch then
			self.marked = true
		else
			self.marked = false
		end
	end,

	refresh = function(self)

		local nodes = self.nodes

		-- this needs to happen whenever the node set is changed
		-- this doesn't solve when things are positioned differently
		-- so i really cannot let containers behave this way

		local cx, cy
		local left, right, top, bottom
		for i = 1, #nodes do
			local position = nodes[i].position
			local x = position[1]
			local y = position[2]
			cx = (cx) and (cx + (1 / #nodes) * x) or ((1 / #nodes) * x)
			cy = (cy) and (cy + (1 / #nodes) * y) or ((1 / #nodes) * y)

			left = (left) and (math.min(left, x)) or (x)
			right = (right) and (math.max(right, x)) or (x)
			top = (top) and (math.min(top, y)) or (y)
			bottom = (bottom) and (math.max(bottom, y)) or (y)
		end

		local w = right - left
		local h = bottom - top
		local ox = w*0.5
		local oy = cy - top
		local sx = 1
		local sy = 1

		self.position = {cx, cy, 1}
		self.size = {w, h}
		self.origin = {ox, oy}
		self.scale = {sx, sy}
	end,
}