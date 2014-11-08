function love.load()

	require('dependencies')()

	-- this isn't ideal
	-- but it will do until I have a scene manager
	function getManager()
		return manager
	end

	lg.setBackgroundColor(7, 54, 66)
	lg.setLineWidth(1)
	input = InputManager()
	manager = ObjectManager()
	viewport = ViewportManager(manager)

	local graph = Graph()

	-- starts a thread with a network connection
	client = ClientManager()

	-- test netcode?
	input:register(viewport, {'input', 'keyboard'})
	input:register(client, {'keyboard'})

	Identifier()


	--love.keyboard.setTextInput(true)

end

function love.update(dt)
	input:update(dt)
	manager:update(dt)
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

end

function love.keyreleased(key, code)
	input:keyreleased(key, code)
end

function love.resize(w, h)
	viewport:resize()
end

function love.threaderror(thread, message)
	print(message)
end