Client = class{
	init = function(self, connection)

		local server = connection.server
		local port = connection.port
		local channel = connection.channel
		local id = connection.id

		local outbound = love.thread.getChannel('outbound')
		local inbound = love.thread.getChannel('inbound')

		self.server = server
		self.port = port
		self.channel = channel
		self.id = id

		self.poll = 1
		self.connected = false

		self.inbound = inbound
		self.outbound = outbound

		-- we will need to do a specific hankshake in order to make use of this
		-- maybe a matching server will 

	end,

	update = function(self, dt)

		local connected = self.connected
		if connected then

			local hub = self.hub
			hub:enterFrame()

			local poll = self.poll

			-- this is just to test connection
			self.timer = self.timer - dt
			if self.timer < 0 then
				self.timer = poll
				local string = 'ping'
				--self:broadcast(string)
			end

			-- pull from outbound channel and broadcast it

			local outbound = self.outbound
			local pending = outbound:getCount()
			for i = 1, pending do
				local message = outbound:pop()
				self:broadcast(message)
			end

		end

	end,

	broadcast = function(self, string)
		local hub = self.hub
		local id = self.id
		local time = love.timer.getTime()

		local message = {
			user = id,
			message = string,
			timestamp = time,
		}
		local data = {message = message}
		hub:publish(data)
	end,

	connect = function(self)

		local server = self.server
		local port = self.port
		local channel = self.channel
		local id = self.id

		local inbound = self.inbound
		local outbound = self.outbound

		local hub = noobhub.new({server = server, port = port})

		hub:subscribe({
			channel = channel,
			callback = function(message)
				if message.user ~= id then
					-- send this to the inbound channel
					inbound:push(message)
				else

					-- we can keep track of ping here
					local time = love.timer.getTime()
					local ping = math.ceil(time - message.timestamp)
					local status = ('own packet retuned in %sms'):format(ping)
					print(status)

				end

			end
		})

		self.hub = hub
		self.timer = 0
		self.connected = true

		local message = 'connected'
		self:broadcast(message)

	end,

	disconnect = function(self)

		-- let everyone know we're leaving
		local message = 'disconnecting'
		self:broadcast(message)

		-- close the socket
		local hub = self.hub
		hub:unsubscribe()

	end,


}

--[[

make a noobhub wrapper which uses a seperate thread?

]]--