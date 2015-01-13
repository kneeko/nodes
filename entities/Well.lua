Well = class{
	init = function(self)

		self._type = 'well'

		local position = {0, 0, 0.7}
		local scale = {1, 1}
		local size = {50, 50}
		local origin = {25, 25}
		local positioning = 'relative'

		self._debug = true

		self.terminals = {}

		self.position = position
		self.scale = scale
		self.origin = origin
		self.size = size
		self.positioning = positioning

		self.callbacks = {'inputpressed', 'inputreleased'}
		self.overrides = {parallax = 1}

		manager:register(self)

	end,

	update = function(self, dt)
	end,

	draw = function(self, identifier, ...)

		local projection = ...

		local x, y = unpack(projection)

		lg.setColor(255, 255, 255)

		local font = lg.getFont()
		local string = 'W'
		local w, h = font:getWidth(string), font:getHeight(string)
		lg.print(string, x - w*0.5, y - h*0.5)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, _, source)

		local hit = self:intersecting(identifier, x, y, 'circle')
		if hit and id == 'l' then

			-- todo
			-- switch this over to a threshold
			local parent = self.parent
			local terminal = Terminal()

			terminal.parent = parent
			terminal:drag(source, identifier, id)
			terminal._graph = self._graph
			terminal._well = self
			terminal:connect(parent)

			parent.terminal = terminal

			table.insert(self.terminals, terminal)

			-- if the terminal doesn't get placed onto a new tile
			-- we will return it to the well

			return true
		elseif hit and id == 'r' then
			-- test emitting a signal
			local terminals = self.terminals
			for _,terminal in ipairs(terminals) do
				local from = terminal.path[1]
				local ping = Ping()
				ping:visit(from)
			end
		end

	end,

	inputreleased = function(self)
	end,
}