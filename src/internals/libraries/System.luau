---------------------------------------
local Raylib = require("@raylib")
---------------------------------------
local rLib = Raylib.lib
local rConsts = Raylib.const
local rStructs = Raylib.structs
---------------------------------------
local Rect = require("@Rect")
local Render = require("@Render")
local Camera = require("@Camera")
local Quail = require("@Quail")
local Collisions = require("@Collisions")

local System = {
    Rect = Rect,
    Camera = Camera,

    Render = Render,
    Collisions = Collisions,

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