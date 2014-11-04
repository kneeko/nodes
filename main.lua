function love.load()

	require('dependencies')()

	-- this isn't ideal
	-- but it will do until I have a scene manager
	function getManager()
		return manager
	end

	lg.setBackgroundColor(7, 54, 66)
	lg.setLineWidth(1)
	manager = ObjectManager()
	viewport = ViewportManager(manager)

	--Grid()
	--Pointer()
	Field()

	love.keyboard.setTextInput(true)

end

function love.update(dt)
	manager:update(dt)
	viewport:update(dt)
end

function love.draw()
	viewport:draw()
end

function love.mousepressed(x, y, button)
	-- maybe viewport gets the callback here
	-- passes it to the manager with worldspace coords?
	viewport:inputpressed(x, y, button)
end

function love.mousereleased(x, y, button)
	viewport:inputreleased(x, y, button)
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