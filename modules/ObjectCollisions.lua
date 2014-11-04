--[[
what does it mean for objects to collide if they are on different depth levels?
it may still be useful for, for example, adding terrain to a group when it runs off the screen.

should this be manager agnostic?
probably not...

how do I consolidate the roles?
right now a collider is a label with a list of keys playing that role
and a collidable needs only check to see if it collides with that label's keys

if I had collision layers or a collision matrix (more apt for a physics simulation) then
everything could have its layers and everything gets checked with everything else

ideally this registers with a signal using the manager context
and listens for calls to it...

each emit can pass the entire object so long as it is never touched...

----

how might I go about handling a general tile locale for quick collision tests?

how do I avoid looping if I want to find if a tile exists?
- nearest to tile resolution from bound
- at what point is this actually faster than checking, though?

]]--

ObjectCollisions = class{
	init = function(self)

		-- colliders, keyed by collider name (sort of like layers)
		local colliders = {}

		-- collidables keyed by object with their own list of collidables
		local collidables = {}

		-- maybe the object manager can be solely responsible for registering the objects

	end,

	update = function(self, dt)
		local colliders = self.colliders
		local collidables = self.collidables
		for _,collidable in pairs(collidables) do
			if collidable.colliders then
				for _,collider in ipairs(colliders) do
					local match = colliders[collider]
					if match then
						self:collide(collider, collidable)
					end
				end
			end
		end
	end,

	register = function(self, key)
		-- add to collidables or colliders
	end,

	release = function(self, key)
		-- remove... how do I find keys if they've been
		-- colliders could potentially change their layer, which would mean they have to be moved from one key to another
		-- how do I detect that and update? maybe a method inside of the Collider subclass
	end,

	collide = function(self, collider, collidable)
		-- test the collidable and the collider for a collision and facilitate their messaging should it occur
		-- gets the actual objects so we need to find out what sort of collision test is wanted
		-- and what kind of response is wanted
	end,
}