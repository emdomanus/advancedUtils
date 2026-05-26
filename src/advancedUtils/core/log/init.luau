--!strict
--!optimize 2
--!native

export type LogLevel = "info" | "warn" | "error"

export type LogRecord = {
	level: LogLevel,
	category: string,
	message: any,
	fields: { [string]: any }?,
	source: string,
	line: number,
	trace: string?,
	time: number,
}

export type LogSink = (record: LogRecord) -> ()

local Log = {}

local CALLER_DEPTH = 4
local DEFAULT_CATEGORY = "Log"

local sinks: { [number]: LogSink } = {}
local nextSinkId = 1
local consoleSinkEnabled = true

local function getCallerInfo(stackDepth: number): (string, number)
	local source = debug.info(stackDepth, "s")
	local line = debug.info(stackDepth, "l")

	return source, line
end

local function formatFields(fields: { [string]: any }?): string
	if not fields then
		return ""
	end

	local keys = {}
	local count = 0
	for key in fields do
		count += 1
		keys[count] = key
	end

	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)

	local values = table.create(count)
	for index = 1, count do
		local key = keys[index]
		values[index] = `{tostring(key)}={tostring(fields[key])}`
	end

	return ` [{table.concat(values, ", ")}]`
end

local function formatRecord(record: LogRecord): string
	return string.format(
		"[%s][%s:%d][%s] %s%s",
		string.upper(record.level),
		record.source,
		record.line,
		record.category,
		tostring(record.message),
		formatFields(record.fields)
	)
end

local function emitConsole(record: LogRecord)
	local formatted = formatRecord(record)

	if record.level == "warn" then
		warn(formatted)
	else
		print(formatted)
	end

	if record.trace then
		if record.level == "warn" then
			warn(record.trace)
		else
			print(record.trace)
		end
	end
end

local function emit(record: LogRecord)
	if consoleSinkEnabled then
		emitConsole(record)
	end

	for _, sink in sinks do
		local ok, err = pcall(sink, record)
		if not ok then
			warn(`[Log] sink failed: {tostring(err)}`)
		end
	end
end

local function makeRecord(
	level: LogLevel,
	message: any,
	category: string?,
	fields: { [string]: any }?,
	stackDepth: number,
	includeTrace: boolean
): LogRecord
	local source, line = getCallerInfo(stackDepth)

	return {
		level = level,
		category = category or DEFAULT_CATEGORY,
		message = message,
		fields = fields,
		source = source,
		line = line,
		trace = if includeTrace then debug.traceback("Stack trace:", 3) else nil,
		time = os.clock(),
	}
end

function Log.setConsoleSinkEnabled(enabled: boolean)
	consoleSinkEnabled = enabled
end

function Log.addSink(sink: LogSink): () -> ()
	local sinkId = nextSinkId
	nextSinkId += 1
	sinks[sinkId] = sink

	return function()
		sinks[sinkId] = nil
	end
end

function Log.clearSinks()
	table.clear(sinks)
end

function Log.info(message: any, category: string?, fields: { [string]: any }?)
	emit(makeRecord("info", message, category, fields, CALLER_DEPTH, false))
end

function Log.warn(message: any, category: string?, fields: { [string]: any }?)
	emit(makeRecord("warn", message, category, fields, CALLER_DEPTH, true))
end

function Log.reportError(message: any, category: string?, fields: { [string]: any }?)
	emit(makeRecord("error", message, category, fields, CALLER_DEPTH, true))
end

function Log.error(message: any, category: string?, fields: { [string]: any }?)
	Log.reportError(message, category, fields)
	error(tostring(message), 2)
end

function Log.assert(condition: any?, message: any, category: string?, fields: { [string]: any }?)
	if condition then
		return
	end

	Log.error(message, category, fields)
end

return Log
