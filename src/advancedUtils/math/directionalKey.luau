--!strict
--!optimize 2
--!native

-- Snaps a character-local direction vector to one of 8 cardinal/diagonal keys.
-- Local space convention: -Z is forward, +X is right.

export type EightDirectionalKey =
	"forward"
	| "forwardRight"
	| "right"
	| "backwardRight"
	| "backward"
	| "backwardLeft"
	| "left"
	| "forwardLeft"

local KEYS: { EightDirectionalKey } = {
	"forward",
	"forwardRight",
	"right",
	"backwardRight",
	"backward",
	"backwardLeft",
	"left",
	"forwardLeft",
}

local TAU = math.pi * 2
local STEP = TAU / 8

local DirectionalKey = {}

-- Snaps a local direction vector to the nearest 45 degree key.
-- forward = -Z, right = +X. Y is ignored.
function DirectionalKey.resolveEightDirectional(localDir: Vector3): EightDirectionalKey
	-- atan2(x, -z) so that -Z (forward) yields angle 0 and +X (right) yields pi/2
	local angle = math.atan2(localDir.X, -localDir.Z)
	-- normalize to [0, TAU)
	angle = (angle % TAU + TAU) % TAU
	local index = math.floor(angle / STEP + 0.5) % 8
	return KEYS[index + 1]
end

return DirectionalKey
