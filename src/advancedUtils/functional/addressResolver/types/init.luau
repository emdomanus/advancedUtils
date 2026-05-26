--!strict

export type PathNode<PathKey> = {
	[PathKey]: PathNode<PathKey> | number,
}

export type AddressConfig<PathKey> = {
	root: PathNode<PathKey> | number,
}

export type AddressPath<PathKey> = { PathKey | number }

export type OffsetNode = {
	offset: number,
	quantity: number,
	children: { [string]: OffsetNode }?,
}

export type AddressResolver<PathKey> = {
	config: AddressConfig<PathKey>,
	_rootNode: OffsetNode,
	_totalSize: number,
	_isBareRoot: boolean,

	getTotalSize: (self: AddressResolver<PathKey>) -> number,
	resolve: (self: AddressResolver<PathKey>, ...PathKey | number) -> number,
	toPath: (self: AddressResolver<PathKey>, address: number) -> AddressPath<PathKey>?,
	getRange: (self: AddressResolver<PathKey>, ...PathKey | number) -> (number, number),
}

return {}