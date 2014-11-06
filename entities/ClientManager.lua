-- this should also happen on another thread
-- which makes life a liiiittle more difficult

ClientManager = class{
	init = function(self, server, port, channel)

		local salt = math.floor(math.random() * 100)
		local id = ('User(%s,%s,%s)'):format(love._os, salt, os.time())
		self.id = id

		self.connected = false
		self:connect()

		print('generated: ' .. id)

		getManager():register(self)

	end,

	update = function(self, dt)

		local connected = self.connected
		if connected then
			local channels = self.channels
			local inbound = channels.inbound

			local pending = inbound:getCount()
			for i = 1, pending do
				local message = inbound:pop()

				local action = tonumber(message.message)
				if action then
					print(action)
					getManager().objects[action]:toggle()
				end

				-- send this message to the correct player model?
				-- for now, use this to activate the node with this key!

			end

			-- get stuff from client
			-- send stuff to client
		end

	end,


	broadcast = function(self, message)

		local connected = self.connected
		if connected then
			local channels = self.channels
			local outbound = channels.outbound
			outbound:push(message)
		end

	end,

	connect = function(self)

		local connected = self.connected

		if not connected then

			local id = self.id

			-- the thread running the client
			local client = love.thread.newThread('threads/thread.lua')

			-- channel for pushing info to the thread
			local dispatch = love.thread.getChannel('dispatch')

			-- channel for broadcasting commands to other users
			local outbound = love.thread.getChannel('outbound')

			-- channel for recieving updates from other users
			local inbound = love.thread.getChannel('inbound')


			-- todo: include uid and maybe something secret
			local connection = {
				server = 'node.kneeko.com',
				port = 1337,
				channel = 'ping-channel',
				id = id,
			}
			
			dispatch:push(connection)
			client:start()

			local channels = {
				dispatch = dispatch,
				outbound = outbound,
				inbound = inbound,
			}

			self.client = client
			self.channels = channels
			self.connected = true

		end

	end,

	disconnect = function(self)

		local connected = self.connected
		if connected then

			local channels = self.channels
			local dispatch = channels.dispatch
			dispatch:push({action = 'stop'})
			self.connected = false

		end

	end,

	keypressed = function(self, key, code)
		if key == 'q' then
			self:disconnect()
		end

		if key == 'r' then
			self:connect()
		end
	end,
		


}

--[[

make a noobhub wrapper which uses a seperate thread?

]]--