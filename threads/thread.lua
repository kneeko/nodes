local thread = {}
function thread.load()

	-- love modules
	require 'love.timer'
	require 'love.filesystem'
	require 'love.math'

	-- import noobhub
	require 'lib/json'
	require 'net/noobhub'

	-- server class
	class = require 'lib/class'
	require 'net/Client'

	-- the channel ClientManager uses to send commands to the thread
	dispatch = love.thread.getChannel('dispatch')

	-- the first thing the client manager will send the thread
	-- is the connection data
	local connection = dispatch:pop()	
	client = Client(connection)
	client:connect()

	running = true

end

function thread.run()

	thread.load()

	local dt = love.timer.getTime()
	local tick = 0.1

	-- main loop
	while running do
		timer = love.timer.getTime() - dt
		if timer > tick then
			dt = love.timer.getTime()
			thread.update(timer)
		end
	end

end



function thread.update(dt)

	-- read queue




	client:update(dt)

	-- get stuff back from 


	-- how i send shit back to the client manager?



	-- if we got a kill event, do thread.stop()
	local pending = dispatch:getCount()
	for i = 1, pending do
		local message = dispatch:pop()
		local action = message.action
		local arguments = message.arguments
		if action and thread[action] then
			thread[action](arguments)
		end
	end

end

function thread.stop()

	print('stopping thread and client!!!')
	client:disconnect()
	running = false

end


thread.run()
