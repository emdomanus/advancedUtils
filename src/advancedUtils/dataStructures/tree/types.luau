--!strict

-- Generic tree node that stores a value of type P
export type TreeNode<K, P> = {
    _tree: Tree<K, P>,
    _parentNode: TreeNode<K, P>?,
    _depth: number,
    _numChildren: number,
    _children: { [K]: TreeNode<K, P>? },
    _value: P?, -- Optional value stored at this node

    AddChild: (TreeNode<K, P>, key: K) -> TreeNode<K, P>,
    RemoveChild: (TreeNode<K, P>, key: K) -> (),
    SetValue: (TreeNode<K, P>, value: P) -> (),
    GetValue: (TreeNode<K, P>) -> P?,
    Deconstruct: (TreeNode<K, P>) -> (),
}

-- Tree container with traversal and lifecycle methods
export type Tree<K, P> = {
    _head: TreeNode<K, P>,

    _maxDepth: number?,
    _maxChildrenPerNode: number?,

    GetNodeAt: (Tree<K, P>, ...K) -> TreeNode<K, P>?,
    SetValueAt: (Tree<K, P>, value: P, ...K) -> (),
    GetValueAt: (Tree<K, P>, ...K) -> P?,
    Deconstruct: (Tree<K, P>) -> (),
}

return {}