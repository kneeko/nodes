MeshTest = class{
	init = function(self)

		local a = {50, 50, 0, 0, 255, 200, 255, 255}
		local b = {50, 150, 0, 0, 255, 255, 200, 255}
		local c = {150, 150, 0, 0, 200, 255, 255, 255}

		local d = {150, 50, 0, 0, 255, 200, 200, 255}
		local e = {150, 150, 0, 0, 200, 255, 200, 255}
		local f = {250, 150, 0, 0, 0, 0, 0, 0}

		local vertices = {a, b, c, d, e, f}

		local mesh = lg.newMesh(vertices, nil, 'triangles')

		self.mesh = mesh
		self.position = {0, 0, 0.5}
		self.scale = {1, 1}
		self.size = {500, 500}

		self.overrides = {parallax = 1}

		getManager():register(self)

	end,

	draw = function(self, ...)
		local position = ...
		local x, y = unpack(position)
		local mesh = self.mesh

		lg.draw(mesh, x, y)
	end,
}