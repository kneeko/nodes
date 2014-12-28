local input, viewport

function love.load()

	local bg = {7, 54, 66}
	love.graphics.setBackgroundColor(bg)

	require('dependencies')()
	math.randomseed(3)

	lg.setLineWidth(1)
	lg.setLineStyle('smooth')

	local id = Identity()

	client = ClientManager()
	client.id = id
	
	input = InputManager()
	manager = ObjectManager(client)
	viewport = ViewportManager(manager)

	local graph = Graph()

	input:register(viewport, 'input', 'keyboard')
	input:register(client, 'keyboard')

	paused = false

end

function love.update(dt)
	input:update(dt)
	if not paused then
		manager:update(dt)
	end
	viewport:update(dt)
end

function love.draw()
	viewport:draw()
end

function love.mousepressed(x, y, button)
	if not love.touch then
		input:mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if not love.touch then
		input:mousereleased(x, y, button)
	end
end

function love.touchpressed(id, x, y, pressure)
	input:touchpressed(id, x, y, pressure)
end

function love.touchreleased(id, x, y, pressure)
	input:touchreleased(id, x, y, pressure)
end

function love.keypressed(key, code)

	input:keypressed(key, code)
	
	if key == 'escape' then
		le.quit()
	end
	if key == '=' then
		local cat = Cat()
	end
	if key == '-' then
		manager:pop()
	end

	if key == ' ' then
		paused = not paused
	end

	-- emulate left and right mouse buttons
	if key == 'lgui' then
		local x, y = lm.getPosition()
		love.mousepressed(x, y, 'r')
	end

	if key == 'lalt' then
		local x, y = lm.getPosition()
		love.mousepressed(x, y, 'l')
	end

end

function love.keyreleased(key, code)
	input:keyreleased(key, code)

	if key == 'lgui' then
		local x, y = lm.getPosition()
		love.mousereleased(x, y, 'r')
	end

	if key == 'lalt' then
		local x, y = lm.getPosition()
		love.mousereleased(x, y, 'l')
	end

	if key == 'r' then
		love.load()
	end

end

function love.resize(w, h)
	viewport:resize()
end

function love.threaderror(thread, message)
	print(message)
end