Camera = class{
	init = function(self, n)
		-- position
		-- origin
		self.x = 0
		self.y = 0
		self.z = 1
		self.r = 0

		local n = n
		local p = 1 / n
		self.p = p
		self.n = n

		self.w = lg.getWidth() * p
		self.h = lg.getHeight()
	end,

	draw = function(self, f)
		self:attach()
		f()
		self:detach()
	end,

	attach = function(self)
	
		local x, y, z = self.x, self.y, self.z
		local r = self.r

		local w = self.w
		local h = self.h

		local p = self.p
		local n = self.n

		--local op = math.abs(1 - p)

		-- what is this doing exactly?
		-- this still doesn't deal with multiple smaller viewports properly...

		--local rz = 1/z
		-- this doesn't handle scaling + rotation
		--local ox = w*0.5*rz + w*0.5*rz - w*0.5*rz*(1/p) + w*op*rz
		--local oy = h*0.5*rz


		lg.push()
		lg.scale(z)

		-- this doesn't handle rotation, but I do not intend to use that
		local ox = w / (2 * z) + w*(n-1)*0.5
		local oy = h / (2 * z)

		-- 1 wants: w * 0
		-- 2 wants: w * 0.5
		-- 3 wants: w * 1
		-- 4 wants: w * 1.5
		-- 5 wants:

		-- rotate around center of viewport
		lg.translate(ox, oy)
		lg.rotate(r)
		
		-- move to draw location
		--local dx = -x + ox * op - ox * p * op
		--local dy = -y

		-- draw at the camera position
		lg.translate(-x, -y)

	end,

	detach = function(self)
		lg.pop()
	end,

	set = function(self, x, y, z, r, origin)
		self.x = x or self.x
		self.y = y or self.y
		self.z = z or self.z
	end,

	zoom = function(self, z)
		self.z = z
	end,

	rotate = function(self, r)
		self.r = r or self.r
	end,

	configure = function(self)
	end,

	project = function(self, ix, iy)
		local x, y, z = self.x, self.y, self.z
		local w, h = self.w, self.h
		local r = self.r
		local cos = math.cos(-r)
		local sin = math.sin(-r)
		local px = (ix - w*0.5) / z
		local py = (iy - h*0.5) / z
		px = px*cos - py*sin
		py = py*cos - px*sin
		px = px + x
		py = py + y
		return px, py
	end,

}