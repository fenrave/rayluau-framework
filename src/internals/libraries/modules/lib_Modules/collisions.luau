----------------------------------------------------
local Render = require("@Render")
local Raylib = require("@Raylib")
----------------------------------------------------
local task = zune.task
local RGEN = zune.random.new()
local Check = Raylib.lib.CheckCollisionRecs
----------------------------------------------------
type ThreadDef = Render.ThreadDef
----------------------------------------------------
type StaticDef = {
	Object: buffer,
	Position: vector,
	Size: vector
}
type StaticData = {
	[vector]: {
		[number]: StaticDef
	}
}
----------------------------------------------------
local ThreadStorage: {
	[thread]: {
		InternalStorage: {buffer}
	}
} = {}
----------------------------------------------------
local PerThreadLimit: number = 5
local CurrentHandler: thread
----------------------------------------------------
local Static: StaticData = if _G.StaticObjects then
						_G.StaticObjects :: StaticData
					else
						(function(): StaticData
							_G.StaticObjects = {}
							return _G.StaticObjects
						end)()
----------------------------------------------------
local NumberCache = {}
----------------------------------------------------
local function GenID(): number
	local Number = RGEN:nextInteger(-999999, 999999)

	if table.find(NumberCache, Number) then
		return GenID()
	end; table.insert(NumberCache, Number)

	return Number
end

local function UpdatePosition(m1Pos: vector, m1Size: vector, StaticDef: StaticDef, DynamicObj: buffer)	
	local m2Pos, m2Size = StaticDef.Position, StaticDef.Size

	local diff: vector = (m1Pos + m1Size) - (m2Pos + m2Size)
	
	local mDis: vector = (m1Size + m2Size) - vector.abs(diff)

	if mDis.x < mDis.y then
		buffer.writef32(DynamicObj, 0, m1Pos.x + (mDis.x * math.sign(diff.x))) ; return
	else
		buffer.writef32(DynamicObj, 4, m1Pos.y + (mDis.y * math.sign(diff.y))) ; return
	end
end

local function CollisionHandler(OptBuffer: buffer?)
	local self = coroutine.running() ; CurrentHandler = self
	local Storage = {
		InternalStorage = {OptBuffer} :: {buffer}
	}; ThreadStorage[self] = Storage
	local DynamicCache = {}

	local Updater = task.spawn(function()
		while true do coroutine.yield()
			for i, DynamicObj in Storage.InternalStorage do
				DynamicCache[DynamicObj] = {
					Pos = vector.create(
						buffer.readf32(DynamicObj, 0),
						buffer.readf32(DynamicObj, 4)
					),
					Size = vector.create(
						buffer.readf32(DynamicObj, 8),
						buffer.readf32(DynamicObj, 12)
					)/2
				}
			end
		end
	end)

	while self do coroutine.yield()
		for Vector, Group in Static do
			for Obj, DynamicDef in DynamicCache do
				if vector.magnitude(Vector - DynamicDef.Pos) > 1000 then
					continue
				end

				for _, StaticDef in Group do

					if Check(Obj, StaticDef.Object) == 0 then
						continue
					end

					UpdatePosition(DynamicDef.Pos, DynamicDef.Size, StaticDef, Obj)
				end
			end
		end
		coroutine.resume(Updater)
	end
end

local DefInit: ThreadDef = {
	Counter = 0,
	MainThread = task.spawn(CollisionHandler, nil),
	UpdateDelay = 0
}

Render:AddThread(GenID(), DefInit)

local function RegisterRect(Rect: buffer)
	local CurrentThread = ThreadStorage[CurrentHandler]
	if #CurrentThread.InternalStorage > PerThreadLimit then
		CurrentThread = task.spawn(CollisionHandler, Rect)
		Render:AddThread(GenID(), {
			Counter = 0,
			MainThread = CurrentThread,
			UpdateDelay = 0
		})
	else
		table.insert(CurrentThread.InternalStorage, Rect)
	end
end


return RegisterRect