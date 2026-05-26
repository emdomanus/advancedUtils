--!strict
--!optimize 2
--!native

export type PowerCurve = {
	coefficient: number,
	exponent: number,
}

local PowerCurve = {}

-- coefficient * x ^ exponent
function PowerCurve.apply(x: number, powerCurve: PowerCurve): number
	return powerCurve.coefficient * (x ^ powerCurve.exponent)
end

-- inverse: (x / coefficient) ^ (1 / exponent)
function PowerCurve.reverse(x: number, powerCurve: PowerCurve): number
	return (x / powerCurve.coefficient) ^ (1 / powerCurve.exponent)
end

return PowerCurve