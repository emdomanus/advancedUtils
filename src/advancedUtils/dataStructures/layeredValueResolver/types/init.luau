--!strict
--!optimize 2
--!native

export type ValueChangeCallback<ValueT> = (newValue: ValueT) -> ()

export type CategorySolver<ValueT, KeyT, AggregateT> = (value: ValueT, aggregate: AggregateT?, key: KeyT) -> ValueT
export type CategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT> = (
	current: AggregateT?,
	modifierValue: ModifierValueT,
	key: KeyT,
	modifier: ModifierT
) -> AggregateT?

export type CategoryDefinition<ValueT, KeyT, ModifierT> = {
	default: any?,
	aggregate: CategoryAggregator<any, KeyT, any, ModifierT>,
	solve: CategorySolver<ValueT, KeyT, any>,
}

export type Config<ValueT, KeyT, LayerT, CategoryT, ModifierT> = {
	defaults: { [KeyT]: ValueT },
	layers: { LayerT },
	modifierLayers: { LayerT },
	categories: { CategoryT },
	categoryDefinitions: { [CategoryT]: CategoryDefinition<ValueT, KeyT, ModifierT> },
}

export type LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT> = {
	addModifier: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		modifier: ModifierT,
		layer: LayerT
	) -> (),
	updateModifier: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		modifier: ModifierT,
		modifiedKeys: { [KeyT]: boolean? }
	) -> (),
	removeModifier: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		modifier: ModifierT
	) -> (),
	getModifierLayer: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		modifier: ModifierT
	) -> LayerT?,
	getValue: (self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>, key: KeyT) -> ValueT,
	getSnapshot: (self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>) -> { [KeyT]: ValueT },
	bindToValueChange: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		key: KeyT,
		callback: ValueChangeCallback<ValueT>,
		runInitially: boolean?
	) -> () -> (),
	unbindFromValueChange: (
		self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		key: KeyT,
		callback: ValueChangeCallback<ValueT>
	) -> (),
	deconstruct: (self: LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>) -> (),
}

export type LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT> & {
		--// PRIVATE STATE
		_config: Config<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
		_statsByLayer: { [LayerT]: { [KeyT]: ValueT } },
		_modifiersByLayer: { [LayerT]: { ModifierT } },
		_modifierIndicesByLayer: { [LayerT]: { [ModifierT]: number } },
		_modifiersToLayer: { [ModifierT]: LayerT? },
		_aggregateModifiers: { [LayerT]: { [CategoryT]: { [KeyT]: any } } },
		_validSnapshot: { [KeyT]: ValueT }?,
		_onChangeCallbacks: { [KeyT]: { [ValueChangeCallback<ValueT>]: boolean }? },

		--// HELPERS
		_getFinalLayer: (self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>) -> LayerT,
		_recomputeAggregates: (
			self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
			layer: LayerT,
			modifiedKeys: { [KeyT]: boolean? }
		) -> (),
		_recomputeLayer: (
			self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
			layer: LayerT,
			modifiedKeys: { [KeyT]: boolean? }
		) -> (),
		_notifyFinalChanges: (
			self: LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>,
			modifiedKeys: { [KeyT]: boolean? }
		) -> (),
	}

return {}
