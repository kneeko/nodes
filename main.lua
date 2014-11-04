function love.load()

	require('dependencies')()

	-- this isn't ideal
	-- but it will do until I have a scene manager
	function getManager()
		return manager
	end

	lg.setBackgroundColor(7, 54, 66)
	manager = ObjectManager()
	viewport = ViewportManager(manager)

	--Grid()
	Field()
	Pointer()

	-- signals should be used for this...

end

function love.update(dt)
	manager:update(dt)
	viewport:update(dt)
end

function love.draw()
	viewport:draw(manager)
end

function love.mousepressed(x, y, button)
	-- maybe viewport gets the callback here
	-- passes it to the manager with worldspace coords?
	manager:mousepressed(x, y, button)
	viewport:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	viewport:mousereleased(x, y, button)
end

function love.keypressed(key, code)
	if key == 'escape' then
		le.quit()
	end
	if key == '=' then
		local cat = Cat()
	end
	if key == '-' then
		manager:pop()
	end

	if tonumber(key) then
		viewport:set(tonumber(key))
	end

	viewport:keypressed(key, code)

end

function love.keyreleased(key, code)
	viewport:keyreleased(key, code)
end

function love.resize(w, h)
	viewport:resize()
end