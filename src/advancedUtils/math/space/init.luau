--!strict
--!optimize 2
--!native

local Space = {}

local EPSILON = 1e-6

function Space.getOverlapArea(part1: BasePart, part2: BasePart): (Vector3, Vector3)
	local part1Position = part1.Position
	local part1Size = part1.Size

	local part2Position = part2.Position
	local part2Size = part2.Size

	local overlapMin = Vector3.new(
		math.max(part1Position.X - part1Size.X / 2, part2Position.X - part2Size.X / 2),
		math.max(part1Position.Y - part1Size.Y / 2, part2Position.Y - part2Size.Y / 2),
		math.max(part1Position.Z - part1Size.Z / 2, part2Position.Z - part2Size.Z / 2)
	)

	local overlapMax = Vector3.new(
		math.min(part1Position.X + part1Size.X / 2, part2Position.X + part2Size.X / 2),
		math.min(part1Position.Y + part1Size.Y / 2, part2Position.Y + part2Size.Y / 2),
		math.min(part1Position.Z + part1Size.Z / 2, part2Position.Z + part2Size.Z / 2)
	)

	local overlapSize = overlapMax - overlapMin
	local overlapPosition = overlapMin + (overlapSize / 2)
	return overlapSize, overlapPosition
end

function Space.getPositionOnTop(part: BasePart, xzOffsetMin: Vector2?, xzOffsetMax: Vector2?): Vector3
	assert(part, "Part cannot be nil")

	local minX, minZ = xzOffsetMin and xzOffsetMin.X or 0, xzOffsetMin and xzOffsetMin.Y or 0
	local maxX, maxZ = xzOffsetMax and xzOffsetMax.X or 0, xzOffsetMax and xzOffsetMax.Y or 0

	local offsetX = minX + math.random() * (maxX - minX)
	local offsetZ = minZ + math.random() * (maxZ - minZ)

	return part.Position + Vector3.new(offsetX, part.Size.Y / 2, offsetZ)
end

function Space.gridify(part: BasePart, surface: Enum.NormalId, numX: number, numY: number): { { Vector3 } }
	assert(part, "Part cannot be nil")
	assert(typeof(surface) == "EnumItem", "Surface must be a valid Enum.NormalId")
	assert(numX > 0 and numY > 0, "numX and numY must be greater than 0")

	local size = part.Size
	local cframe = part.CFrame

	local right, up, origin
	if surface == Enum.NormalId.Top then
		right, up, origin = cframe.RightVector, cframe.LookVector, cframe.Position + cframe.UpVector * (size.Y / 2)
	elseif surface == Enum.NormalId.Bottom then
		right, up, origin = cframe.RightVector, -cframe.LookVector, cframe.Position - cframe.UpVector * (size.Y / 2)
	elseif surface == Enum.NormalId.Front then
		right, up, origin = cframe.RightVector, cframe.UpVector, cframe.Position + cframe.LookVector * (size.Z / 2)
	elseif surface == Enum.NormalId.Back then
		right, up, origin = cframe.RightVector, -cframe.UpVector, cframe.Position - cframe.LookVector * (size.Z / 2)
	elseif surface == Enum.NormalId.Left then
		right, up, origin = -cframe.LookVector, cframe.UpVector, cframe.Position - cframe.RightVector * (size.X / 2)
	elseif surface == Enum.NormalId.Right then
		right, up, origin = cframe.LookVector, cframe.UpVector, cframe.Position + cframe.RightVector * (size.X / 2)
	else
		error("Invalid surface provided")
	end

	local stepX = size.X / numX
	local stepY = size.Z / numY
	if surface == Enum.NormalId.Top or surface == Enum.NormalId.Bottom then
		stepX = size.X / numX
		stepY = size.Z / numY
	elseif surface == Enum.NormalId.Left or surface == Enum.NormalId.Right then
		stepX = size.Z / numX
		stepY = size.Y / numY
	else
		stepX = size.X / numX
		stepY = size.Y / numY
	end

	local grid = {}
	for x = 0, numX do
		grid[x] = {}
		for y = 0, numY do
			local offsetX = (x - numX / 2) * stepX
			local offsetY = (y - numY / 2) * stepY
			grid[x][y] = origin + right * offsetX + up * offsetY
		end
	end

	return grid
end

function Space.getSurfaceArea(size: Vector3): number
	return 2 * (size.X * size.Y + size.Y * size.Z + size.Z * size.X)
end

function Space.edgeDistanceAlong(size: Vector3, direction: Vector3): number
	local mag = direction.Magnitude
	if mag < EPSILON then
		return 0
	end
	local d = direction / mag
	local half = size / 2

	local maxRatio = 0
	if math.abs(d.X) > EPSILON then
		local r = math.abs(d.X) / half.X
		if r > maxRatio then
			maxRatio = r
		end
	end
	if math.abs(d.Y) > EPSILON then
		local r = math.abs(d.Y) / half.Y
		if r > maxRatio then
			maxRatio = r
		end
	end
	if math.abs(d.Z) > EPSILON then
		local r = math.abs(d.Z) / half.Z
		if r > maxRatio then
			maxRatio = r
		end
	end

	if maxRatio <= 0 then
		return 0
	end
	return 1 / maxRatio
end

function Space.edgePointAlong(size: Vector3, direction: Vector3): Vector3
	local mag = direction.Magnitude
	if mag < EPSILON then
		return Vector3.zero
	end
	local d = direction / mag
	return d * Space.edgeDistanceAlong(size, d)
end

return Space
