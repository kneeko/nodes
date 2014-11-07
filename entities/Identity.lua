Identity = class{
	init = function(self)

		-- load a file, create one if empty
		-- this profile can be passed around perhaps?
		self._filename = 'identity'

		self:load()
		
	end,

	load = function(self)

		-- load file
		local filename = self._filename
		local exists = love.filesystem.exists(filename)
		if not exists then
			self:create()
		end

		local data = jupiter.load(filename)
		for key,val in pairs(data) do
			self[key] = val
		end

		local status = ('Loaded identity profile: %s'):format(self.id)
		print(status)

	end,

	save = function(self, data)

		-- save file
		jupiter.save(data)

	end,

	create = function(self)

		local filename = self._filename
		local identifier = Identifier()
		local salt = identifier:get()
		local timestamp = os.time()
		local os = love._os

		local id = ('User(%s,%s,%s)'):format(os, timestamp, salt)
		local hash = md5(id)

		self.os = os
		self.salt = salt
		self.timestamp = timestamp
		self.id = id
		self.hash = hash

		local data = {
			_filename = filename,
			os = os,
			salt = salt,
			timestamp = timestamp,
			id = id,
			hash = hash,
		}

		self:save(data)

	end,

	get = function(self)

		-- use the hash a the primary id string
		-- so that we are not sending out the user os and creation time
		local hash = self.id
		local id = self.id
		return hash, id

	end,

	delete = function(self)

	end,

	validate = function(self)
	end,
}