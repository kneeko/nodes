Tile = class{
	init = function(self, nodes)
		self._type = 'tile'

		
		-- is passed references to nodes for its children
		-- uses their position and order to draw the fill

		self.nodes = nodes

		local alpha = 170 + 30 * math.random()
		local color = {42, 161, 152, 120 + 80 * math.random()}
		self.alpha = alpha
		self.color = color

		self.boundry = 30
		self.threshold = 15




		self:refresh()

		if math.random() > 0.99 then
			--Token(self)
		end

		-- could use the nodes as its bound check?

		self.includes = {Listener}

		self.marked = false
		self.highlight = false


		manager:register(self)

		self:listen('marked')

	end,

	update = function(self, dt)
		self:refresh()
	end,

	draw = function(self, identifier, ...)
		-- i need to get the position of each node as projected, not just their own position
		local position = ...
		local x, y = unpack(position)

		local nodes = self.nodes
		local points = self.points

		-- why are some tiles being drawn twice?

		local color = self.color
		local alpha = self.alpha
		if self.marked then
			color = {255, 149, 0, alpha}
		end

		lg.setColor(color)
		lg.polygon('fill', points)

		--lg.setColor(255, 255, 255, 100)
		lg.setColor(0, 43, 54)
		lg.setColor(255, 255, 255, 50)
		lg.setColor(89, 152, 152)
		lg.polygon('line', points)

		lg.setColor(101, 123, 131)

		--local mesh = self.mesh
		--lg.setColor(255, 255, 255)
		--lg.draw(mesh, 0, 0)

		local threshold = self.threshold
		local boundry = self.boundry

		lg.setColor(255, 255, 255, 50)

		local cat = self.cat
		if cat then
			lg.setColor(255, 255, 255)
			--lg.print(cat._key, x - 50, y)
			lg.setColor(180, 255, 180, 150)
		end


		--lg.circle('line', x, y, boundry + threshold)
		--lg.circle('line', x, y, boundry)

		local font = lg.getFont()
		local string = ''
		if self.terminal then
			string = '(' .. self.terminal._key .. ')'
		end
		local w, h = font:getWidth(string), font:getHeight(string)
		lg.setColor(255, 255, 255)
		lg.print(string, x - w*0.5, y - h*0.5 + 35)

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
		local points = self.points or {}




		-- this needs to happen whenever the node set is changed
		-- this doesn't solve when things are positioned differently
		-- so i really cannot let containers behave this way

		-- this doesn't work right now!
		local inset = 0

		local cx, cy
		local left, right, top, bottom

		local color = self.color

		--local vertices = {}
		for i = 1, #nodes do

			local x, y = unpack(nodes[i].position)

			--local vertex = {x, y, 0, 0, color[1], color[2], color[3], color[4]}
			--table.insert(vertices, vertex)

			points[i*2 - 1] = x*(1 - inset)
			points[i*2] = y*(1 - inset)

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

		--[[
		local vertices = {}
		local inset = 20
		for i = 1, #points, 2 do
			local x = points[i]
			local y = points[i + 1]
			local angle = math.atan2(cy - y, cx - x)
			local px = x + math.cos(angle) * inset
			local py = y + math.sin(angle) * inset
			vertices[#vertices + 1] = px
			vertices[#vertices + 1] = py
		end

		self.vertices = vertices
		]]--

		self.points = points
		


		local polygon = Polygon(unpack(points))
		self.polygon = polygon

		--local mesh = lg.newMesh(vertices, nil, 'fan')
		--self.mesh = mesh

	end,
}