local Rect = require("@Rect")
local Render = require("@Render")
local Texture = require("@Texture")
local task = zune.task
---------------------------------------
type InternalEntity = {
	LastPosition: vector
} & Entity

export type Entity = {
	Velocity: vector,
	Direction: vector,
	Position: vector,

	Pulse: (self: InternalEntity, Direction: vector, Intensity: number) -> (),
	Reset: (self: InternalEntity) -> (),

	Rectangle: Rect.Rect,
	Texture: Texture.Texture?,

	_InternalRef: InternalEntity
}
---------------------------------------
export type Read = {
	Position: (Entity: InternalEntity) -> vector,
	Velocity: (Entity: InternalEntity) -> vector,
	[string]: (Entity: InternalEntity) -> any
}

export type Write = {
	Position: (Entity: InternalEntity, Value: vector) -> (),
	Velocity: (Entity: InternalEntity, Value: vector) -> (),
	[string]: (Entity: InternalEntity, Value: vector) -> ()
}

export type MetaBehaviors = {
	__index: keyof<Read>,
	__newindex: keyof<Write>
}
---------------------------------------
local Entities: {InternalEntity} = {}
local HandlerStore: {[thread]: {
	Active: {InternalEntity}
}} = {}
local PerThreadLimit = 15
local CurrentThread: thread = nil :: any
---------------------------------------
local Behaviors: {Read: Read, Write: Write} = {
	Read = {
		Position = function(Entity: InternalEntity)
			return Entity.Rectangle.Position
		end,
		Velocity = function(Entity: InternalEntity)
			return Entity.Velocity
		end,
		Rectangle = function(Entity: InternalEntity)
			return Entity.Rectangle
		end,
		Direction = function(Entity: InternalEntity)
			return Entity.Direction
		end
	},
	Write = {
		Position = function(Entity: InternalEntity, Value: vector)
			Entity.Rectangle.Position = Value
		end,
		Velocity = function(Entity: InternalEntity, Value: vector)
			Entity.Velocity = Value
		end,
		Direction = function(Entity: InternalEntity, Value: vector)
			Entity.Direction = Value
		end
	}
}

local function VelocityHandler()
	local Self = coroutine.running()

	local Storage = (function()
		HandlerStore[Self] = {Active = {}}
		return HandlerStore[Self]
	end)()
	
	coroutine.yield()

	while true do coroutine.yield()
		if Render.IsDrawing then
			continue
		end

		for _,Entity in Storage.Active do
			local Direction = if Entity.Direction == vector.zero then Entity.Direction else vector.normalize(Entity.Direction)
			Entity.Direction = vector.zero
			local Velocity = Direction + (Entity.Velocity * .8)
			
			Entity.Rectangle.Position += Velocity
			Entity.Velocity = Velocity
		end
	end
end

local function VelocityThread()
	while true do task.wait(1/240)
		for thread in HandlerStore do
			coroutine.resume(thread)
		end
	end
end; task.spawn(VelocityThread)

local function NewEntity(Rectangle: Rect.Rect): Entity
	local NewEntity = {
		Position = Rectangle.Position,
		Velocity = vector.zero,

		Direction = vector.zero,

		LastPosition = Rectangle.Position,

		Rectangle = Rectangle
	} :: InternalEntity

	if not CurrentThread then
		CurrentThread = coroutine.create(VelocityHandler) ; coroutine.resume(CurrentThread)
	elseif #HandlerStore[CurrentThread].Active > PerThreadLimit then
		CurrentThread = coroutine.create(VelocityHandler) ; coroutine.resume(CurrentThread)
	end; 

	table.insert(HandlerStore[CurrentThread :: thread].Active, NewEntity)

	local ReturnEntity: Entity = setmetatable({
		Pulse = function(self: Entity, Direction: vector, Intensity: number)
		end
	} :: Entity, {
		__index = function(Entity: InternalEntity, Index: string)
			return Behaviors.Read[Index](NewEntity)
		end,
		__newindex = function(Entity: InternalEntity, Index: string, Value: any)
			Behaviors.Write[Index](NewEntity, Value)
		end
	})

	return ReturnEntity

end


return NewEntity