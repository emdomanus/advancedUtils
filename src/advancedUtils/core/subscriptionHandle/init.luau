--!strict

export type SubscriptionHandle = {
	addSubscription: (self: SubscriptionHandle, callback: () -> ()) -> () -> (),
	clearSubscriptions: (self: SubscriptionHandle) -> (),
	deconstruct: (self: SubscriptionHandle) -> (),
}

export type SubscriptionHandleImpl = SubscriptionHandle & {
	subscriptions: { () -> () },
}

local SubscriptionHandle = {}
SubscriptionHandle.__index = SubscriptionHandle

function SubscriptionHandle.new(existingTable: {}?): SubscriptionHandle
	local self: SubscriptionHandleImpl = setmetatable(existingTable or {}, SubscriptionHandle) :: any
	self.subscriptions = {}
	return self
end

function SubscriptionHandle.addSubscription(self: SubscriptionHandleImpl, cb: () -> ()): () -> ()
	table.insert(self.subscriptions, cb)

	return function()
		local idx = table.find(self.subscriptions, cb)
		if idx then
			table.remove(self.subscriptions, idx)
		end
	end
end

function SubscriptionHandle.clearSubscriptions(self: SubscriptionHandleImpl): ()
	for _, unSub in self.subscriptions do
		unSub()
	end
	table.clear(self.subscriptions)
end

function SubscriptionHandle.deconstruct(self: SubscriptionHandleImpl): ()
	self:clearSubscriptions()
	self.subscriptions = {}
end

return SubscriptionHandle
