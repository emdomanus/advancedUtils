--!strict
--!optimize 2
--!native

local AddressResolver = require(script.functional.addressResolver)
local Bootstrap = require(script.core.bootstrap)
local CoreTable = require(script.core.table)
local DirectionalKey = require(script.math.directionalKey)
local Dictionary = require(script.functional.dictionary)
local Guard = require(script.functional.guard)
local Hook = require(script.core.hook)
local IdAllocator = require(script.core.idAllocator)
local LayeredMap = require(script.dataStructures.layeredMap)
local LayeredValueResolver = require(script.dataStructures.layeredValueResolver)
local Log = require(script.core.log)
local MinHeap = require(script.dataStructures.minHeap)
local PowerCurve = require(script.math.powerCurve)
local PriorityQueue = require(script.dataStructures.priorityQueue)
local Promise = require(script.core.promise)
local Sample = require(script.functional.sample)
local SubscriptionHandle = require(script.core.subscriptionHandle)
local Text = require(script.functional.text)
local Tree = require(script.dataStructures.tree)

local AdvancedUtils = {
	core = require(script.core),
	dataStructures = require(script.dataStructures),
	functional = require(script.functional),
	math = require(script.math),
}

export type AdvancedUtils = typeof(AdvancedUtils)

export type AddressConfig<PathKey> = AddressResolver.AddressConfig<PathKey>
export type AddressResolver<PathKey> = AddressResolver.AddressResolver<PathKey>
export type AmbiguouslyNested<K, V> = Dictionary.AmbiguouslyNested<K, V>
export type AnyTable = CoreTable.AnyTable
export type BootstrapAPI<SharedT, ServerT, ClientT> = Bootstrap.BootstrapAPI<SharedT, ServerT, ClientT>
export type BootstrapPhase = Bootstrap.BootstrapPhase
export type CompactNumberOptions = Text.CompactNumberOptions
export type CurveType = Sample.CurveType
export type DeltaChainEntry = CoreTable.DeltaChainEntry
export type EightDirectionalKey = DirectionalKey.EightDirectionalKey
export type EnsuredLayeredMap<K, V> = LayeredMap.EnsuredLayeredMap<K, V>
export type Executor<T> = Promise.Executor<T>
export type FlatIdDictionary<V> = Dictionary.FlatIdDictionary<V>
export type GuardFn<T> = Guard.GuardFn<T>
export type HeapEntry<T> = MinHeap.HeapEntry<T>
export type HookCallback<T...> = Hook.Callback<T...>
export type HookHandle<T...> = Hook.HookHandle<T...>
export type IdAllocator = IdAllocator.IdAllocator
export type LayeredMap<K, V> = LayeredMap.LayeredMap<K, V>
export type LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	LayeredValueResolver.LayeredValueResolver<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolverCategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT> =
	LayeredValueResolver.CategoryAggregator<ModifierValueT, KeyT, AggregateT, ModifierT>
export type LayeredValueResolverCategoryDefinition<ValueT, KeyT, ModifierT> =
	LayeredValueResolver.CategoryDefinition<ValueT, KeyT, ModifierT>
export type LayeredValueResolverCategorySolver<ValueT, KeyT, AggregateT> =
	LayeredValueResolver.CategorySolver<ValueT, KeyT, AggregateT>
export type LayeredValueResolverConfig<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	LayeredValueResolver.Config<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT> =
	LayeredValueResolver.LayeredValueResolverHandle<ValueT, KeyT, LayerT, CategoryT, ModifierT>
export type LoadFlatIdDictionaryOptions<V> = Dictionary.LoadFlatIdDictionaryOptions<V>
export type LogLevel = Log.LogLevel
export type LogRecord = Log.LogRecord
export type LogSink = Log.LogSink
export type MinHeap<T> = MinHeap.MinHeap<T>
export type NestedTable<K, V> = CoreTable.NestedTable<K, V>
export type NestedValueOrTable<K, V> = CoreTable.NestedValueOrTable<K, V>
export type OffsetNode = AddressResolver.OffsetNode
export type OneOfConfig<T> = Sample.OneOfConfig<T>
export type OptionalSource = Dictionary.OptionalSource
export type PathNode<PathKey> = AddressResolver.PathNode<PathKey>
export type PowerCurve = PowerCurve.PowerCurve
export type PriorityQueue<T> = PriorityQueue.PriorityQueue<T>
export type Promise<T> = Promise.Promise<T>
export type RangeConfig = Sample.RangeConfig
export type Resolvable<T> = Sample.Resolvable<T>
export type SampleFn<T> = Sample.SampleFn<T>
export type SampleShape<K, T> = Sample.SampleShape<K, T>
export type SubscriptionHandle = SubscriptionHandle.SubscriptionHandle
export type Tree<K, P> = Tree.Tree<K, P>

return AdvancedUtils
