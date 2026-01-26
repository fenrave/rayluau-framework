---------------------------------------
export type TaggedList<Type = any> = {
	read AddTag: (self: TaggedList<Type>, Tag: string, Index: number | buffer) -> TaggedList<Type>,
	read RemoveTag: (self: TaggedList<Type>, Tag: string) -> (),

	_Tags: {[string]: buffer},

	Iterate: (
		self: TaggedList<Type>,
		func: (Object: Type, Tag: string) -> ()
	) -> (),

	[string]: Type
}
---------------------------------------
export type Pool<Type = any> = {
	Name: string,
	ObjectList: {Type} | setmetatable<{Type}, {any}>,
	Amount: number,
	ObjectRef: FFIStructureType,
	CurrentIndex: number,
	Args: {[any]: any},
	TagGroups: {
		[string]: TaggedList<Type>
	},

	TagGroup: (self: Pool<Type>, TagGroup: string) -> TaggedList<Type>,
	GetTagGroup: (self: Pool<Type>, TagGroup: string) -> TaggedList<Type>,

	Populate: (self: Pool<Type>, number?) -> Pool<Type>,
	SetSize: (self: Pool<Type>, number) -> Pool<Type>,
	SetTo: (self: Pool<Type>, number) -> Pool<Type>,
	Shrink: (self: Pool<Type>) -> Pool<Type>,

	GetNext: (self: Pool<Type>) -> any,
	GetByOffset: (self: Pool<Type>, number) -> buffer,

	Iterate: (self: Pool<Type>, (Object: Type, Index: number)->()) -> Pool<Type>,

	PopByIndex: (self: Pool<Type>, Index: number) -> Pool<Type>,
	PopCurrent: (self: Pool<Type>) -> Pool<Type>,

	OptComponent: Type,
	CurrentObject: buffer,
	InternalList: {buffer}
}
---------------------------------------
export type ExportList<Type> = TaggedList | Type
---------------------------------------
local function Iterator(self: Pool, fn: (...any) -> ()): ()
	for i: number = 1, self.Amount do
		fn(self.ObjectList[i], i)
	end
end

local PoolFunc = {
	TagGroup = function(NewPool: Pool, TagGroup: string): TaggedList<any>
		local InternalComponent = table.clone(NewPool.OptComponent)
		NewPool.TagGroups[TagGroup] = setmetatable({
			AddTag = function(self: TaggedList, Tag: string, Index: number | buffer)
				if typeof(Index) == "number" then
					self._Tags[Tag] = NewPool.InternalList[Index]
				else
					self._Tags[Tag] = Index
				end
				return self
			end,
			RemoveTag = function(self: TaggedList, Tag: string)
				self._Tags[Tag] = nil
			end,
			Iterate = function(self: TaggedList, func)
				for Index, Tag in self._Tags do
					func(self[Index], Index)
				end
			end,
			_Tags = {},
		} :: TaggedList, {
			__index = function(List: TaggedList, Index: string): ()
				(InternalComponent :: any).Object = List._Tags[Index]
				return InternalComponent :: any | any
			end
		})

		type TagType = typeof(NewPool.TagGroups[TagGroup]._Tags)

		return NewPool.TagGroups[TagGroup]
	end,

	Iterate = function(self: Pool, fn: (Object: any, Index: number) -> ()): Pool
		Iterator(self, fn) ; return self
	end,

	GetTagGroup = function(self: Pool, TagGroup: string)
		return self.TagGroups[TagGroup]
	end,

	GetNext = function(self: Pool)
		return self.ObjectList[if self.CurrentIndex + 1 > self.Amount then 1 else self.CurrentIndex + 1]
	end,

	GetByOffset = function(self: Pool, Offset: number): buffer
		return self.ObjectList[math.clamp(self.CurrentIndex + Offset, 0, self.Amount)]
	end,

	PopByIndex = function(self: Pool, Index: number)
		table.insert(self.InternalList, table.remove(self.InternalList, Index) :: buffer)
		self.CurrentIndex = #self.InternalList
		return self
	end,

	PopCurrent = function(self: Pool)
		table.insert(self.InternalList, table.remove(self.InternalList, self.CurrentIndex) :: buffer)
		self.CurrentIndex = #self.InternalList
		return self
	end,

	SetSize = function(self: Pool, Amn: number): Pool
		self.CurrentIndex = math.clamp(self.Amount, 0, Amn)
		self.Amount = Amn; return self
	end,

	Populate = function(self: Pool): Pool
		for i: number = 1, self.Amount do
			self.ObjectList[i] = self.ObjectRef:new(self.Args)
		end; return self
	end,

	Shrink = function(self: Pool): Pool
		for Index, Value in self.ObjectList do
			if Index > self.Amount then
				self.ObjectList[Index] = nil
			end
		end; return self
	end
}
---------------------------------------

local function ReturnPool<Type>(
		PoolName: string,
		ObjectType: FFIStructureType,
		Amount: number,
		OptComponent: Type | any,
		Param: {any}
	): Pool<Type>

	local NewPool = {} :: Pool<Type>

	NewPool.Name = PoolName
	NewPool.ObjectRef = ObjectType ; NewPool.Amount = Amount

	NewPool.ObjectList = {}
	NewPool.CurrentIndex = 0

	NewPool.OptComponent = OptComponent
	NewPool.InternalList = NewPool.ObjectList
	NewPool.TagGroups = {}

	NewPool.ObjectList = setmetatable({}, {
			__index = function(List: {buffer}, Index: number)
				if Index == NewPool.CurrentIndex then
					return NewPool.OptComponent
				end
				NewPool.CurrentObject = NewPool.InternalList[Index];
				(NewPool.OptComponent :: any).Object = NewPool.InternalList[Index]
				NewPool.CurrentIndex = Index

				return NewPool.OptComponent
			end,
			__newindex = NewPool.InternalList
		}
	)
	-- NewPool.ObjectList[1] = OptComponent.Object

	NewPool.Args = Param
	
	NewPool.Iterate = PoolFunc.Iterate
	NewPool.GetTagGroup = PoolFunc.GetTagGroup
	NewPool.GetNext = PoolFunc.GetNext
	NewPool.GetByOffset = PoolFunc.GetByOffset
	NewPool.SetSize = PoolFunc.SetSize
	NewPool.Populate = PoolFunc.Populate
	NewPool.Shrink = PoolFunc.Shrink
	NewPool.PopByIndex = PoolFunc.PopByIndex
	NewPool.PopCurrent = PoolFunc.PopCurrent


	NewPool.TagGroup = PoolFunc.TagGroup

	return NewPool
end

return ReturnPool