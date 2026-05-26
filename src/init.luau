--!strict
--!optimize 2
--!native

local AdvancedUtils = require(script.advancedUtils)

export type AdvancedUtils = AdvancedUtils.AdvancedUtils

export type AddressConfig<PathKey> = AdvancedUtils.AddressConfig<PathKey>
export type AddressResolver<PathKey> = AdvancedUtils.AddressResolver<PathKey>
export type AmbiguouslyNested<K, V> = AdvancedUtils.AmbiguouslyNested<K, V>
export type AnyTable = AdvancedUtils.AnyTable
export type BootstrapAPI<SharedT, ServerT, ClientT> = AdvancedUtils.BootstrapAPI<SharedT, ServerT, ClientT>
export type BootstrapPhase = AdvancedUtils.BootstrapPhase
export type CompactNumberOptions = AdvancedUtils.CompactNumberOptions
export type CurveType = AdvancedUtils.CurveType
export type DeltaChainEntry = AdvancedUtils.DeltaChainEntry
export type EightDirectionalKey = AdvancedUtils.EightDirectionalKey
export type EnsuredLayeredMap<K, V> = AdvancedUtils.EnsuredLayeredMap<K, V>
export type Executor<T> = AdvancedUtils.Executor<T>
export type FlatIdDictionary<V> = AdvancedUtils.FlatIdDictionary<V>
export type GuardFn<T> = AdvancedUtils.GuardFn<T>
export type HeapEntry<T> = AdvancedUtils.HeapEntry<T>
export type HookCallback<T...> = AdvancedUtils.HookCallback<T...>
export type HookHandle<T...> = AdvancedUtils.HookHandle<T...>
export type IdAllocator = AdvancedUtils.IdAllocator
export type LayeredMap<K, V> = AdvancedUtils.LayeredMap<K, V>
export type LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	AdvancedUtils.LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolverCategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT> =
	AdvancedUtils.LayeredValueResolverCategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT>
export type LayeredValueResolverCategoryDefinition<ValueT, KeyT, ModifierT> =
	AdvancedUtils.LayeredValueResolverCategoryDefinition<ValueT, KeyT, ModifierT>
export type LayeredValueResolverCategorySolver<ValueT, KeyT, AggregateT> =
	AdvancedUtils.LayeredValueResolverCategorySolver<ValueT, KeyT, AggregateT>
export type LayeredValueResolverConfig<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	AdvancedUtils.LayeredValueResolverConfig<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	AdvancedUtils.LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LoadFlatIdDictionaryOptions<V> = AdvancedUtils.LoadFlatIdDictionaryOptions<V>
export type LogLevel = AdvancedUtils.LogLevel
export type LogRecord = AdvancedUtils.LogRecord
export type LogSink = AdvancedUtils.LogSink
export type MinHeap<T> = AdvancedUtils.MinHeap<T>
export type NestedTable<K, V> = AdvancedUtils.NestedTable<K, V>
export type NestedValueOrTable<K, V> = AdvancedUtils.NestedValueOrTable<K, V>
export type OffsetNode = AdvancedUtils.OffsetNode
export type OneOfConfig<T> = AdvancedUtils.OneOfConfig<T>
export type OptionalSource = AdvancedUtils.OptionalSource
export type PathNode<PathKey> = AdvancedUtils.PathNode<PathKey>
export type PowerCurve = AdvancedUtils.PowerCurve
export type PriorityQueue<T> = AdvancedUtils.PriorityQueue<T>
export type Promise<T> = AdvancedUtils.Promise<T>
export type RangeConfig = AdvancedUtils.RangeConfig
export type Resolvable<T> = AdvancedUtils.Resolvable<T>
export type SampleFn<T> = AdvancedUtils.SampleFn<T>
export type SampleShape<K, T> = AdvancedUtils.SampleShape<K, T>
export type SubscriptionHandle = AdvancedUtils.SubscriptionHandle
export type Tree<K, P> = AdvancedUtils.Tree<K, P>

return AdvancedUtils
