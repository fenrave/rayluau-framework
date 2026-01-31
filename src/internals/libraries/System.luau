---------------------------------------
local Raylib = require("@raylib")
local IO = zune.io
local out = IO.stdout
local task = zune.task
---------------------------------------
local rLib = Raylib.lib
local rConsts = Raylib.const
local rStructs = Raylib.structs
---------------------------------------
local SysVer = "0.1.0"
local Header =  `\x1b[39m\n\n> Framework \x1b[33mVersion: {SysVer}\x1b[39m\n`..
				`> Using Zune \x1b[35mPlatform: {string.upper(zune.platform.os)}\x1b[39m\n\n`

task.delay(.5, out.write, out, Header)

local Rect = require("@Rect")
local Render = require("@Render")
local Camera = require("@Camera")
local Quail = require("@Quail")
local Collisions = require("@Collisions")
local Input = require("@Input")
local Texture = require("@Texture")
local Entity = require("@Entity")

local System = {
	Rect = Rect,
	Camera = Camera,
	Texture = Texture,

	Entity = Entity,

	Render = Render,
	Collisions = Collisions,
	Input = Input,

	--Raylib
	rLib = rLib,
	rConsts = rConsts,
	rStructs = rStructs,
	
	Utils = {
		Case = require("@Case"),
		Pool = require("@Pool"),
		Quail = Quail
	}
}
---------------------------------------
export type Rectangle = Rect.Rect
export type Camera = Camera.Camera
---------------------------------------


return System :: typeof(System)