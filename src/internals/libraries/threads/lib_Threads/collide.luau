-------------------------------------------
local q = require("@Types.Quail")
local Raylib = require("@raylib").lib
local Check = Raylib.CheckCollisionRecs
-------------------------------------------
local ffi = zune.ffi
local task = zune.task
-------------------------------------------
type StaticDef = {
	Object: buffer,
	Position: vector,
	Size: vector
}

type CollidableData = {buffer}

type ThreadStorage = {
	[thread]: {
		InternalStorage: {FFIPointer}
	}
}
-------------------------------------------
local Timer = 1/60
local PerThreadLimit: number = 10
local CurrentHandler: thread

local ThreadStorage: ThreadStorage = {}
-------------------------------------------
local function UpdatePosition(m1Pos: vector, m1Size: vector, StaticDef: StaticDef, DynamicObj: FFIPointer)
	local m2Pos: vector, m2Size: vector = StaticDef.Position, StaticDef.Size
	local diff: vector = (m1Pos + m1Size) - (m2Pos + m2Size)
	
	local mDis: vector = (m1Size + m2Size) - vector.abs(diff)

	if mDis.x < mDis.y then
		zune.io.stderr:lock("none")
		DynamicObj:writef32(0, m1Pos.x + (mDis.x * math.sign(diff.x)))
		zune.io.stderr:unlock()
	else
		zune.io.stderr:lock("none")
		DynamicObj:writef32(4, m1Pos.y + (mDis.y * math.sign(diff.y)))
		zune.io.stderr:unlock()
	end
end

local function CollisionHandler(List: {buffer}, Field: q.ThreadInterface)
	local Static: {[vector]: {StaticDef}} = Field.Bevy.Get("Static")
	local DynamicCache: {
		[FFIPointer]: {
			Pos: vector,
			Size: vector,
			TempBuffer: buffer
		}
	} = {} ; local self = coroutine.running()

	local Ptrs: {FFIPointer} = {}

	for _,BAddress in List do
		table.insert(Ptrs, ffi.ptrFromAddress(BAddress))
	end
	local Storage: {[string]: {FFIPointer}} = {
		InternalStorage = Ptrs
	}; ThreadStorage[self] = Storage

	local Updater = task.spawn(function()
		while true do
			for i, DynamicObj in Storage.InternalStorage do
				if not DynamicCache[DynamicObj] then
					DynamicCache[DynamicObj] = {} :: any
				end
				zune.io.stderr:lock("none")
				local Pos: vector = vector.create(
					DynamicObj:readf32(0),
					DynamicObj:readf32(4)
				)
				zune.io.stderr:unlock()
				zune.io.stderr:lock("none")
				local Size = vector.create(
					DynamicObj:readf32(8),
					DynamicObj:readf32(12)
				)/2
				zune.io.stderr:unlock()
				DynamicCache[DynamicObj] = {
					Pos = Pos,
					Size = Size,
					TempBuffer = (function()
						local Buffer: buffer = DynamicCache[DynamicObj].TempBuffer
						if not Buffer then
							Buffer = buffer.create(16)
						end

						buffer.writef32(Buffer, 0, Pos.x)
						buffer.writef32(Buffer, 4, Pos.y)
						buffer.writef32(Buffer, 8, Size.x)
						buffer.writef32(Buffer, 12, Size.y)

						return Buffer
					end)()
				}
			end
			task.wait(Timer/2)
		end
	end)

	while true do
		for Vector, Group: {StaticDef} in Static do
			for Obj, DynamicDef in DynamicCache do
				if vector.magnitude(Vector - DynamicDef.Pos) > 1000 then
					continue
				end

				for _, StaticDef in Group do
					if Check(DynamicDef.TempBuffer, StaticDef.Object) == 0 then
						continue
					end

					UpdatePosition(DynamicDef.Pos, DynamicDef.Size, StaticDef, Obj)
				end
			end
		end

		task.wait(Timer)
	end

end

local CurrentThread: thread? = nil

local function Cycle(PtrList: {buffer}, Interface: q.ThreadInterface, Context: number)
	CurrentThread = coroutine.create(CollisionHandler)

	local FinalList: {buffer} = {}
	local SpillOver: {buffer} = {}

	if #PtrList > PerThreadLimit then
		table.move(PtrList, 1, PerThreadLimit, 1, FinalList)
		table.move(PtrList, PerThreadLimit + 1, #PtrList, 1, SpillOver)
		Cycle(SpillOver, Interface, Context)
	else
		FinalList = PtrList
	end

	task.spawn(CurrentThread, FinalList, Interface)
end

return Cycle
