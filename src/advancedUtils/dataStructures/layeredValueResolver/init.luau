--!strict
--!optimize 2
--!native

local Types = require(script.types)

export type CategorySolver<ValueT, KeyT, AggregateT> = Types.CategorySolver<ValueT, KeyT, AggregateT>
export type CategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT> =
	Types.CategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT>
export type CategoryDefinition<ValueT, KeyT, ModifierT> = Types.CategoryDefinition<ValueT, KeyT, ModifierT>
export type Config<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	Types.Config<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	Types.LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	Types.LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>

local LayeredValueResolver = {}
LayeredValueResolver.__index = LayeredValueResolver

local function cloneDefaults<ValueT, KeyT>(defaults: { [KeyT]: ValueT }): { [KeyT]: ValueT }
	return table.clone(defaults)
end

local function getLayerIndex<LayerT>(layers: { LayerT }, layer: LayerT): number?
	for index, candidate in layers do
		if candidate == layer then
			return index
		end
	end
	return nil
end

local function collectModifierKeys<KeyT, CategoryT, ModifierT>(
	categories: { CategoryT },
	modifier: ModifierT
): { [KeyT]: boolean? }
	local modifiedKeys = {}
	local modifierTable = modifier :: any

	for _, category in categories do
		local categoryValues = modifierTable[category]
		if categoryValues == nil then
			continue
		end

		for key in categoryValues do
			modifiedKeys[key] = true
		end
	end

	return modifiedKeys
end

function LayeredValueResolver.new<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	config: Config<ValueT, KeyT, LayerT, CategoryT, ModifierT>
): LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
	local self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
		setmetatable({}, LayeredValueResolver) :: any

	self._config = config
	self._statsByLayer = {}
	self._modifiersByLayer = {}
	self._modifierIndicesByLayer = {}
	self._modifiersToLayer = {}
	self._aggregateModifiers = {}
	self._validSnapshot = nil
	self._onChangeCallbacks = {}

	for _, layer in config.layers do
		self._statsByLayer[layer] = cloneDefaults(config.defaults)
	end

	for _, layer in config.modifierLayers do
		self._modifiersByLayer[layer] = {}
		self._modifierIndicesByLayer[layer] = {}
		self._aggregateModifiers[layer] = {}

		for _, category in config.categories do
			self._aggregateModifiers[layer][category] = {}
		end
	end

	return self
end

function LayeredValueResolver._getFinalLayer<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
): LayerT
	return self._config.layers[#self._config.layers]
end

function LayeredValueResolver._recomputeAggregates<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	layer: LayerT,
	modifiedKeys: { [KeyT]: boolean? }
): ()
	local aggregateByCategory = self._aggregateModifiers[layer]
	if aggregateByCategory == nil then
		return
	end

	for _, category in self._config.categories do
		local definition = self._config.categoryDefinitions[category]
		local categoryAggregate = aggregateByCategory[category]

		for key in modifiedKeys do
			categoryAggregate[key] = definition.default
		end

		for _, modifier in self._modifiersByLayer[layer] do
			local categoryValues = (modifier :: any)[category]
			if categoryValues == nil then
				continue
			end

			for key in modifiedKeys do
				local modifierValue = categoryValues[key]
				if modifierValue == nil then
					continue
				end

				categoryAggregate[key] =
					definition.aggregate(categoryAggregate[key], modifierValue, key, modifier)
			end
		end
	end
end

function LayeredValueResolver._recomputeLayer<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	layer: LayerT,
	modifiedKeys: { [KeyT]: boolean? }
): ()
	if not next(modifiedKeys) then
		return
	end

	local layerIndex = getLayerIndex(self._config.layers, layer)
	if layerIndex == nil or layerIndex <= 1 then
		return
	end

	self:_recomputeAggregates(layer, modifiedKeys)

	local sourceLayer = self._config.layers[layerIndex - 1]
	local sourceLayerStats = self._statsByLayer[sourceLayer]
	local layerStats = self._statsByLayer[layer]
	local aggregateByCategory = self._aggregateModifiers[layer]
	local propagatedKeys = {}

	for key in modifiedKeys do
		local newValue = sourceLayerStats[key]

		for _, category in self._config.categories do
			local definition = self._config.categoryDefinitions[category]
			local categoryAggregate = aggregateByCategory[category]
			local aggregate = if categoryAggregate[key] ~= nil then categoryAggregate[key] else definition.default
			newValue = definition.solve(newValue, aggregate, key)
		end

		if layerStats[key] ~= newValue then
			layerStats[key] = newValue
			propagatedKeys[key] = true
		end
	end

	local nextLayer = self._config.layers[layerIndex + 1]
	if nextLayer ~= nil then
		self:_recomputeLayer(nextLayer, propagatedKeys)
	elseif next(propagatedKeys) then
		self:_notifyFinalChanges(propagatedKeys)
	end
end

function LayeredValueResolver._notifyFinalChanges<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	modifiedKeys: { [KeyT]: boolean? }
): ()
	self._validSnapshot = nil

	local finalStats = self._statsByLayer[self:_getFinalLayer()]
	for key in modifiedKeys do
		local callbacks = self._onChangeCallbacks[key]
		if callbacks == nil then
			continue
		end

		for callback in callbacks do
			callback(finalStats[key])
		end
	end
end

function LayeredValueResolver.addModifier<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	modifier: ModifierT,
	layer: LayerT
): ()
	if self._modifiersToLayer[modifier] ~= nil then
		warn("modifier already exists")
		return
	end

	local layerModifiers = self._modifiersByLayer[layer]
	local layerIndices = self._modifierIndicesByLayer[layer]
	if layerModifiers == nil or layerIndices == nil then
		warn("invalid modifier layer")
		return
	end

	table.insert(layerModifiers, modifier)
	layerIndices[modifier] = #layerModifiers
	self._modifiersToLayer[modifier] = layer

	self:_recomputeLayer(layer, collectModifierKeys(self._config.categories, modifier))
end

function LayeredValueResolver.updateModifier<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	modifier: ModifierT,
	modifiedKeys: { [KeyT]: boolean? }
): ()
	local layer = self._modifiersToLayer[modifier]
	if layer == nil then
		warn("UNTRACKED MODIFIER")
		return
	end

	self:_recomputeLayer(layer, modifiedKeys)
end

function LayeredValueResolver.removeModifier<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	modifier: ModifierT
): ()
	local layer = self._modifiersToLayer[modifier]
	if layer == nil then
		warn("UNTRACKED MODIFIER")
		return
	end

	local layerModifiers = self._modifiersByLayer[layer]
	local layerIndices = self._modifierIndicesByLayer[layer]
	local index = if layerIndices then layerIndices[modifier] else nil
	if layerModifiers == nil or layerIndices == nil or index == nil then
		warn("doesnt exist, cant remove")
		return
	end

	local modifiedKeys = collectModifierKeys(self._config.categories, modifier)

	table.remove(layerModifiers, index)
	layerIndices[modifier] = nil
	self._modifiersToLayer[modifier] = nil

	for nextIndex = index, #layerModifiers do
		layerIndices[layerModifiers[nextIndex]] = nextIndex
	end

	self:_recomputeLayer(layer, modifiedKeys)
end

function LayeredValueResolver.getModifierLayer<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	modifier: ModifierT
): LayerT?
	return self._modifiersToLayer[modifier]
end

function LayeredValueResolver.getValue<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	key: KeyT
): ValueT
	return self._statsByLayer[self:_getFinalLayer()][key]
end

function LayeredValueResolver.getSnapshot<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
): { [KeyT]: ValueT }
	if self._validSnapshot ~= nil then
		return self._validSnapshot
	end

	local snapshot = table.clone(self._statsByLayer[self:_getFinalLayer()])
	self._validSnapshot = snapshot
	return snapshot
end

function LayeredValueResolver.bindToValueChange<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	key: KeyT,
	callback: (newValue: ValueT) -> (),
	runInitially: boolean?
): () -> ()
	local callbacks = self._onChangeCallbacks[key]
	if callbacks == nil then
		callbacks = {}
		self._onChangeCallbacks[key] = callbacks
	end

	callbacks[callback] = true

	if runInitially == true then
		callback(self:getValue(key))
	end

	return function()
		self:unbindFromValueChange(key, callback)
	end
end

function LayeredValueResolver.unbindFromValueChange<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
	key: KeyT,
	callback: (newValue: ValueT) -> ()
): ()
	local callbacks = self._onChangeCallbacks[key]
	if callbacks == nil then
		return
	end

	callbacks[callback] = nil
end

function LayeredValueResolver.deconstruct<ValueT, KeyT, LayerT, CategoryT, ModifierT>(
	self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
): ()
	table.clear(self._modifiersToLayer)
	table.clear(self._onChangeCallbacks)

	for _, stats in self._statsByLayer do
		table.clear(stats)
	end
	table.clear(self._statsByLayer)

	for _, modifiers in self._modifiersByLayer do
		table.clear(modifiers)
	end
	table.clear(self._modifiersByLayer)

	for _, indices in self._modifierIndicesByLayer do
		table.clear(indices)
	end
	table.clear(self._modifierIndicesByLayer)

	for _, aggregateByCategory in self._aggregateModifiers do
		for _, aggregate in aggregateByCategory do
			table.clear(aggregate)
		end
		table.clear(aggregateByCategory)
	end
	table.clear(self._aggregateModifiers)

	self._validSnapshot = nil
end

return LayeredValueResolver
