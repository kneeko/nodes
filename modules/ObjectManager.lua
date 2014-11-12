ObjectManager = class{
	init = function(self, client)

		local available = {}
		local objects = {}
		local sorter = ObjectSorter(objects)
		local renderer = ObjectRenderer(objects, sorter)
		local transmitter = Transmitter(client)
		local identifier = Identifier()

		self.client = client
		self.available = available
		self.objects = objects
		self.sorter = sorter
		self.renderer = renderer
		self.transmitter = transmitter
		self.index = {}
		self._identifier = identifier

		print('ObjectManager init\'d with identifier ' .. identifier:get())

	end,

	update = function(self, dt)

		local client = self.client
		client:update(dt)

		local objects = self.objects
		local sorter = self.sorter
		local heap = self:get()
		for i = 1, #heap do
			local key = heap[i]
			local object = objects[key]
			if object._active then
				if object.update then
					object:update(dt)
				end
				if object.compute then
					object:compute()
				end
				if object._listening then
					object:verify()
				end
				-- do I need to call this every frame?
				-- hopefully not...
				--sorter:move(key)
			end
		end

	end,

	prepare = function(self, identifier, camera, viewport)
		-- generate a list of visible scene objects and cache their projection
		local renderer = self.renderer
		renderer:prepare(identifier, camera, viewport)

	end,

	flush = function(self, identifier)
		-- invalidate projection caches for a specific identifier
		local objects = self.objects
		local heap = self:get()
		for i = 1, #heap do
			local key = heap[i]
			local object = objects[key]
			object.projections[identifier] = nil
		end
		local renderer = self.renderer
		renderer:flush(identifier)

		print('Flushed cached projections and draw queues for viewport with id: ' .. identifier)

	end,

	-- called by the viewport manager
	draw = function(self, identifier, camera, bound)
		local renderer = self.renderer
		renderer:draw(identifier, camera, bound)
	end,

	callback = function(self, method, ...)

		local index = self.index
		local objects = self.objects
		local keys = index[method]
		if keys then
			for _,key in ipairs(keys) do
				local object = objects[key]
				object[method](object, ...)
			end
		end

	end,

	register = function(self, object)

		local objects = self.objects
		local sorter = self.sorter
		local available = self.available
		local transmitter = self.transmitter
		local heap = self:get() or {}
		local identifier = self._identifier:get()

		local key
		for i,suggestion in ipairs(available) do
			local suggestion = available[i]
			table.remove(available, i)
			local n = heap[#heap]
			if n then
				if suggestion < heap[#heap] then
					key = suggestion
					break
				end
			end
		end

		-- if there was nothing available then just add a new key
		key = key or #objects + 1

		-- store the main reference to the object
		objects[key] = object

		-- copy fallback values from entity
		object:include(Entity:init(key, identifier))
		object:include(Entity)

		-- include any requested classes
		local includes = object.includes or {}
		for _,include in ipairs(includes) do
			object:include(include:init())
			object:include(include)
		end

		-- index any requested callbacks
		-- are these ever going to be something apart from input?
		-- if so, I could skip this and just register them with that!
		-- although if I want to do some processing specific to the object manager
		-- this lets me filter them through that
		local index = self.index
		local callbacks = object.callbacks or {}
		for _,callback in ipairs(callbacks) do
			index[callback] = index[callback] or {}
			index[callback][#index[callback] + 1] = key
		end

		sorter:insert(key)
		transmitter:register(key, object)

		return key
	end,

	release = function(self, key)

		local objects = self.objects
		local available = self.available
		local sorter = self.sorter
		local transmitter = self.transmitter
		local index = self.index
		local heap = self:get()
		local object = objects[key]
		if type(object) == 'table' then
			local callbacks = object.callbacks or {}
			for _,callback in ipairs(callbacks) do
				local keys = index[callback] or {}
				for i,v in ipairs(keys) do
					if v == key then
						table.remove(keys, i)
					end 
				end
			end
			sorter:remove(key)
			transmitter:release(key)
			available[#available + 1] = key
			objects[key] = nil
		end
		
	end,

	pop = function(self)
		local objects = self.objects
		local heap = self:get()
		local i = math.ceil(#heap * math.random())
		local key = heap[i]
		if key then
			self:release(key)
		end
	end,

	get = function(self)
		local objects = self.objects
		local heap = {}
		for key,object in pairs(objects) do
			heap[#heap + 1] = key
		end
		return heap
	end,

	propogate = function(self, method, ...)
		local objects = self.objects
		local index = self.index
		if index[method] then
			for _,key in ipairs(index[method]) do
				local object = objects[key]
				if object[method] then
					object[method](object, ...)
				else
					local identifier = self._identifier:get()
					local err = string.format('[%s] object %s with type "%s" has not defined callback %s.',
						identifier, object._key, object._type, method)
					print(err)
				end
			end
		end
	end,

	inputpressed = function(self, ...)
		--local identifier, x, y, button = ...
		-- how do I keep this viewport agnostic?
		self:propogate('inputpressed', ...)
	end,

	inputreleased = function(self, ...)
		--local x, y, button = ...
		-- how do I keep this viewport agnostic?
		self:propogate('inputreleased', ...)
	end,

}