DragManager = class{
	init = function(self)

		local events = {}
		local active = 0
		self.events = events
		self.active = active

	end,

	update = function(self, dt)

		local events = self.events
		for id,event in pairs(events) do
			event:update(dt)
		end

	end,

	add = function(self, x, y, id, pressure, source)

		local events = self.events
		local event = DragEvent(x, y, id, pressure, source)
		events[id] = event

		local active = self.active
		self.active = active + 1

	end,

	get = function(self)

		local active = self.active

		if active > 0 then
			local sx, sy, sp = 0, 0, 0
			local events = self.events
			for id,event in pairs(events) do
				local cx, cy, cp = event:get()
				sx = sx + cx
				sy = sy + cy
				sp = sp + cp
			end

			return sx, sy, sp
		end

	end,

	delta = function(self)

		local active = self.active
		if active > 0 then

			local sx, sy, sp = 0, 0, 0

			local events = self.events
			for id,event in pairs(events) do
				local dx, dy, dp = unpack(event.moved)
				sx = sx + dx
				sy = sy + dy
				sp = sp + dp
			end

			return sx, sy, sp
		end

	end,

	remove = function(self, x, y, id, pressure)


		local events = self.events
		if events[id] then
			events[id] = nil
			local active = self.active
			self.active = active - 1
		end

	end,
}