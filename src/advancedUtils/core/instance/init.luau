--!strict
--!optimize 2
--!native

local InstanceUtils = {}

function InstanceUtils.applyVisualModelDefaults(root: Instance): ()
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Massless = true
			descendant.EnableFluidForces = false
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

return InstanceUtils
