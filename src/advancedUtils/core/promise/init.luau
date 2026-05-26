--!strict
--!native
--!optimize 2

-- Promise (formerly SimplePromise)

export type Resolve<T> = (value: T) -> ()
export type Reject = (err: any) -> ()
export type BindToCancel = (fn: () -> ()) -> ()

export type Promise<T> = {
	_resolved: boolean,
	_rejected: boolean,
	_cancelled: boolean,

	_value: T?,
	_error: any?,

	_callbacks: { (T) -> () },
	_errbacks: { (any) -> () },
	_waiters: { thread },
	_cancelHandlers: { () -> () },

	andThen: (self: Promise<T>, fn: (T) -> ()) -> Promise<T>,
	catch: (self: Promise<T>, fn: (any) -> ()) -> Promise<T>,

	await: (self: Promise<T>) -> T,

	cancel: (self: Promise<T>) -> (),
	isPending: (self: Promise<T>) -> boolean,
	isResolved: (self: Promise<T>) -> boolean,
	isRejected: (self: Promise<T>) -> boolean,
	isCancelled: (self: Promise<T>) -> boolean,
}

-- Executor can be minimal:
--   Promise.new(function(resolve) ... end)
-- or include reject:
--   Promise.new(function(resolve, reject) ... end)
-- or include cancel binding:
--   Promise.new(function(resolve, reject, onCancel) ... end)
export type Executor<T> = (resolve: Resolve<T>, reject: Reject, bindToCancel: BindToCancel) -> ()

local Promise = {}
Promise.__index = Promise

local function safeCall(tag: string, fn: () -> ())
	local ok, err = pcall(fn :: () -> any)
	if not ok then
		warn(tag .. ": " .. tostring(err))
	end
end

function Promise.new<T>(executor: Executor<T>): Promise<T>
	local self: Promise<T> = setmetatable({}, Promise) :: any

	self._resolved = false
	self._rejected = false
	self._cancelled = false

	self._value = nil
	self._error = nil

	self._callbacks = {} :: { (T) -> () }
	self._errbacks = {} :: { (any) -> () }
	self._waiters = {} :: { thread }
	self._cancelHandlers = {} :: { () -> () }

	local function settleClear()
		table.clear(self._callbacks)
		table.clear(self._errbacks)
		table.clear(self._cancelHandlers)
	end

	local function resolve(value: T)
		if self._resolved or self._rejected or self._cancelled then
			return
		end

		self._resolved = true
		self._value = value

		for _, fn in self._callbacks do
			fn(value)
		end

		for _, th in self._waiters do
			coroutine.resume(th, true, value)
		end

		table.clear(self._waiters)
		settleClear()
	end

	local function reject(err: any)
		if self._resolved or self._rejected or self._cancelled then
			return
		end

		self._rejected = true
		self._error = err

		for _, fn in self._errbacks do
			fn(err)
		end

		for _, th in self._waiters do
			coroutine.resume(th, false, err)
		end

		table.clear(self._waiters)
		settleClear()
	end

	local function bindToCancelImpl(fn: () -> ())
		if self._cancelled then
			-- already cancelled: run immediately so caller can clean up
			safeCall("Error in Promise cancel handler", fn)
			return
		end
		if self._resolved or self._rejected then
			-- already settled: don't track cancel
			return
		end
		table.insert(self._cancelHandlers, fn)
	end

	-- We always *provide* reject/bindToCancel at runtime;
	-- the executor type allows ignoring them (optional params).
	local ok, err = pcall(function()
		executor(resolve, reject, bindToCancelImpl)
	end)
	if not ok then
		reject(err)
	end

	return self
end

function Promise.resolve<T>(value: T): Promise<T>
	return Promise.new(function(resolve)
		resolve(value)
	end)
end

function Promise.reject<T>(err: any): Promise<T>
	return Promise.new(function(_resolve, reject)
		(reject :: Reject)(err)
	end)
end

-- Cancelling the "all" promise cancels all children.
-- Reject fast on first rejection and cancel the rest.
function Promise.all<K, T>(promises: { [K]: Promise<T> }): Promise<{ [K]: T }>
	return Promise.new(function(resolve, reject, bindToCancel)
		local results: { [K]: T } = {}
		local remaining = 0
		local settled = false

		for _ in pairs(promises) do
			remaining += 1
		end

		if remaining == 0 then
			resolve(results)
			return
		end

		(bindToCancel :: BindToCancel)(function()
			for _, p in pairs(promises) do
				p:cancel()
			end
		end)

		local function onReject(err: any)
			if settled then
				return
			end
			settled = true

			for _, p in pairs(promises) do
				p:cancel()
			end

			(reject :: Reject)(err)
		end

		for k, p in pairs(promises) do
			p:andThen(function(value: T)
				if settled then
					return
				end

				results[k] = value
				remaining -= 1

				if remaining == 0 then
					settled = true
					resolve(results)
				end
			end):catch(onReject)
		end
	end)
end

function Promise.andThen<T, U>(self: Promise<T>, fn: (T) -> U): Promise<U>
	return Promise.new(function(resolve, reject)
		local function handle(value: T)
			local result = fn(value)
			-- if result is itself a promise, wait for it
			if type(result) == "table" and type(result.andThen) == "function" then
				result:andThen(resolve):catch(reject)
			else
				resolve(result :: any)
			end
		end

		if self._resolved then
			handle(self._value :: T)
		elseif not self._rejected and not self._cancelled then
			table.insert(self._callbacks, handle)
			table.insert(self._errbacks, reject)
		else
			reject(self._error)
		end
	end)
end

function Promise.catch<T>(self: Promise<T>, fn: (any) -> ()): Promise<T>
	if self._rejected then
		fn(self._error)
	elseif not self._resolved and not self._cancelled then
		table.insert(self._errbacks, fn)
	end
	return self
end

function Promise.await<T>(self: Promise<T>): T
	if self._resolved then
		return self._value :: T
	end
	if self._rejected then
		error(self._error, 2)
	end
	if self._cancelled then
		error("Promise.await() called on a cancelled promise", 2)
	end

	local th = coroutine.running()
	if not th then
		error("Promise.await() must be called from a yielding thread", 2)
	end

	table.insert(self._waiters, th)

	local ok, payload = coroutine.yield()
	if not ok then
		-- payload is either rejection error or nil (cancel)
		if payload ~= nil then
			error(payload, 2)
		end
		error("Promise was cancelled", 2)
	end

	return payload :: T
end

function Promise.cancel<T>(self: Promise<T>): ()
	if self._resolved or self._rejected or self._cancelled then
		return
	end

	self._cancelled = true

	for _, fn in self._cancelHandlers do
		safeCall("Error in Promise cancel handler", fn)
	end
	table.clear(self._cancelHandlers)

	table.clear(self._callbacks)
	table.clear(self._errbacks)

	for _, th in self._waiters do
		coroutine.resume(th, false, nil)
	end
	table.clear(self._waiters)
end

function Promise.isPending<T>(self: Promise<T>): boolean
	return not (self._resolved or self._cancelled or self._rejected)
end

function Promise.isResolved<T>(self: Promise<T>): boolean
	return self._resolved
end

function Promise.isRejected<T>(self: Promise<T>): boolean
	return self._rejected
end

function Promise.isCancelled<T>(self: Promise<T>): boolean
	return self._cancelled
end

return Promise
