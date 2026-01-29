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

type DynDef = {
	Pos: vector,
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

local function CheckCollisions(M1Pos: vector, M1Size: vector, M2Pos: vector, M2Size: vector): boolean
	if  (M1Pos.x < (M2Pos.x + M2Size.x) and (M1Pos.x + M1Size.x) > M2Pos.x) and
		(M1Pos.y < (M2Pos.y + M2Size.y) and (M1Pos.y + M1Size.y) > M2Pos.y) then
		return true
	else
		return false
	end
end

local function UpdatePosition(StaticDef: StaticDef, DynDef: DynDef, DynamicObj: buffer)
	local m2Pos, m2Size = StaticDef.Position, StaticDef.Size
	local m1Pos, m1Size = DynDef.Pos, DynDef.Size
	local diff: vector = (m1Pos + m1Size) - (m2Pos + m2Size)

	local mDis: vector = (m1Size + m2Size) - vector.abs(diff)

	if mDis.x < mDis.y then
		buffer.writef32(DynamicObj, 0, (m1Pos.x) + ((mDis.x) * math.sign(diff.x)))
	else
		buffer.writef32(DynamicObj, 4, (m1Pos.y) + ((mDis.y) * math.sign(diff.y)))
	end
end
---------------------------------------
local function CollisionHandler(OptBuffer: buffer?)
	local self = coroutine.running() ; CurrentHandler = self

	local Storage = {
		InternalStorage = {OptBuffer} :: {buffer}
	}; ThreadStorage[self] = Storage
	
	local DynamicCache: {[buffer]: DynDef} = {}

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

	while self do coroutine.resume(Updater)
		for Vector, Group in Static do
			for Obj, DynamicDef in DynamicCache do
				if vector.magnitude(Vector - DynamicDef.Pos) > 1000 then
					continue
				end

				for _, StaticDef in Group do
					if not CheckCollisions(DynamicDef.Pos, DynamicDef.Size*2, StaticDef.Position, StaticDef.Size*2) then
						continue
					end

					UpdatePosition(StaticDef, DynamicDef, Obj)
				end
			end
		end
		
		task.wait(1/180)
	end
end; task.spawn(CollisionHandler, nil)
---------------------------------------

local function RegisterRect(Rect: buffer)
	local CurrentThread = ThreadStorage[CurrentHandler]
	if #CurrentThread.InternalStorage > PerThreadLimit then
		CurrentThread = task.spawn(CollisionHandler, Rect)
	else
		table.insert(CurrentThread.InternalStorage, Rect)
	end
end


return RegisterRect