Port = class{
	init = function(self, nodes)

		self._type = 'port'

		self.position = {0, 0, 0.9}
		self.size = {12, 12}
		self.scale = {1, 1}
		self.origin = {6, 6}
		self.nodes = nodes
		self.fudging = 2

		-- if all tiles are uncontested then the port is traversable
		self.tiles = {}

		-- anything it shares a node with is a neighboring port
		self.neighbors = {}

		self.overrides = {parallax = 1}
		self.callbacks = {'inputpressed', 'inputreleased'}

		self:refresh()

		getManager():register(self)

	end,

	draw = function(self, ...)

		local position = ...
		local x, y = unpack(position)

		local color = self.marked and {255, 100, 0} or {0, 255, 255}
		lg.setColor(color)

		lg.circle('line', x, y, 6, 12)
		lg.print(self._key, x, y)

	end,

	-- get own position
	refresh = function(self)

		local nodes = self.nodes

		local label = ''

		local x, y
		local checked = {}
		for i,a in ipairs(nodes) do
			label = label .. a.label
			for j,b in ipairs(nodes) do
				if a ~= b and (not checked[b._key]) then

					local nx, ny = midpoint(a.position, b.position)
					x = (x) and (x + nx) * 0.5 or (nx)
					y = (y) and (y + ny) * 0.5 or (ny)

				end
			end
			checked[a._key] = true
		end

		local position = self.position
		position[1] = x
		position[2] = y

		self.label = label

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)

		if tonumber(id) or id == 'l' then
			if self:intersecting(identifier, x, y) then
				self:toggle()
			end
		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)
	end,

	toggle = function(self)
		self.marked = not self.marked
	end,
}