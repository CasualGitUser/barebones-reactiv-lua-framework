function newHelper(o, meta)
	setmetatable(o, meta)
	return o
end

local function fromInstanceHelper(stream, instance: Instance)
	instance.Changed:Connect(function(property) stream:emit(property) end)
	return stream
end

local function fromRBXScriptSignalHelper(stream, rbx_script_signal: RBXScriptSignal)
	rbx_script_signal:Connect(function(...)
		stream:emit(...)
	end)
	return stream
end

local function mapHelper(self, stream, f)
	self:onEvent(function(...) stream:emit(f(...)) end)
	return stream
end

local function flatMapHelper(self, stream, f)
	self:onEvent(function(...) f(...):onEvent(function(...) stream:emit(...) end) end)
	return stream
end

local function filterHelper(self, stream, predicate)
	self:onEvent(function(...) if predicate(...) then stream:emit(...) end end)
	return stream
end

local function scanHelper(self, stream, acc, f)
	self:onEvent(function(...) acc = f(acc, ...) stream:emit(acc) end)
	return stream
end

local function mergeHelper(self, stream, ...)
	self:onEvent(function(...) stream:emit(...) end)
	for _, other in ipairs({...}) do
		other:onEvent(function(...) stream:emit(...) end)
	end
	return stream
end

local function skipUntilHelper(self, stream, predicate)
	local skipping = true
	self:onEvent(function(...) if not skipping then stream:emit(...) elseif predicate(...) then skipping = false end end)
	return stream
end

local function bufferHelper(self, stream, duration)
	local lastEmit = time()
	local bufferValues = {}
	self:onEvent(function(...) if time() - lastEmit < duration then
			if #{...} == 0 then table.insert(bufferValues, {}) end
			for _, value in ipairs({...}) do
				table.insert(bufferValues, value)
			end
		end end)
	task.defer(function()
		while true do
			wait(duration)
			if #bufferValues == 0 then return end
			lastEmit = time()
			stream:emit(bufferValues)
			bufferValues = {}
		end
	end)
	return stream
end

----------------------------------- REACTIVE -------------------------------------
local Reactive = {}
Reactive.__index = Reactive

function Reactive.new() return newHelper({listeners = {}}, Reactive) end

function Reactive.fromInstance(instance: Instance) return fromInstanceHelper(Reactive.new(), instance) end

function Reactive.fromInterval(interval) 
	local reactive = Reactive.new()
	task.defer(function() while true do wait(interval) reactive:emit() end end)
	return reactive
end

function Reactive.fromRBXScriptSignal(rbx_script_signal: RBXScriptSignal) return fromRBXScriptSignalHelper(Reactive.new(), rbx_script_signal) end

function Reactive:emit(...)
	for _, listener in self.listeners do listener(...) end
end

function Reactive:onEvent(listener)
	table.insert(self.listeners, listener)
end

function Reactive:map(f) return mapHelper(self, Reactive.new(), f) end

function Reactive:flatMap(f) return flatMapHelper(self, Reactive.new(), f) end

function Reactive:filter(predicate) return filterHelper(self, Reactive.new(), predicate) end

function Reactive:scan(init, f: (any, any) -> (any)) return scanHelper(self, Reactive.new(), init, f) end

function Reactive:merge(...) return mergeHelper(self, Reactive.new(), ...) end

function Reactive:skipUntil(predicate) return skipUntilHelper(self, Reactive.new(), predicate) end

function Reactive:buffer(duration) return bufferHelper(self, Reactive.new(), duration) end

----------------------------------- SIGNAL -------------------------------------
local Signal = {}
Signal.__index = Signal
setmetatable(Signal, Reactive)

function Signal.new(value) return newHelper({listeners = {}, value = value}, Signal) end

function Signal.fromInstance(instance: Instance) return fromInstanceHelper(Signal.new(), instance) end

function Signal.fromRBXScriptSignal(rbx_script_signal: RBXScriptSignal) return fromRBXScriptSignalHelper(Signal.new(), rbx_script_signal) end

function Signal.fromValueBase(value_base: ValueBase)
	local Signal = fromRBXScriptSignalHelper(Signal.new(), value_base.Changed)
	Signal:emit(value_base.Value)
	return Signal
end

function Signal.fromAttribute(object: Instance, attribute: string)
	local Signal = fromRBXScriptSignalHelper(Signal.new(), object:GetAttributeChangedSignal(attribute))
	return Signal:map(function() return object:GetAttribute(attribute) end)
end

function Signal:emit(value)
	self.value = value
	Reactive.emit(self, value)
end

function Signal:map(f) return mapHelper(self, Signal.new(), f) end

function Signal:flatMap(f) return flatMapHelper(self, Signal.new(), f) end

function Signal:filter(predicate) return filterHelper(self, Signal.new(), predicate) end

function Signal:scan(init, f: (any, any) -> (any)) return scanHelper(self, Signal.new(), init, f) end

function Signal:merge(...) return mergeHelper(self, Signal.new(), ...) end

function Signal:skipUntil(predicate) return skipUntilHelper(self, Signal.new(), predicate) end

function Signal:buffer(duration) return bufferHelper(self, Signal.new(), duration) end

return {
	Reactive = Reactive,
	Signal = Signal
}
