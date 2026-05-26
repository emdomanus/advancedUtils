--!strict

local types = require(script.Parent.types)

type TreeNode<K, P> = types.TreeNode<K, P>
type Tree<K, P> = types.Tree<K, P>

local TreeNode = {}
TreeNode.__index = TreeNode

function TreeNode.new<K, P>(tree: Tree<K, P>, parentNode: TreeNode<K, P>?): TreeNode<K, P>
    local self = setmetatable({}, TreeNode) :: TreeNode<K, P>

    self._tree = tree
    self._parentNode = parentNode
    self._depth = if parentNode then parentNode._depth + 1 else 0
    self._numChildren = 0
    self._children = {}
    self._value = nil

    return self
end

function TreeNode.AddChild<K, P>(self: TreeNode<K, P>, key: K): TreeNode<K, P>
    if not self._children[key] then
        if self._tree._maxChildrenPerNode and self._numChildren >= self._tree._maxChildrenPerNode then
            error("Max children per node exceeded")
        end
        self._children[key] = TreeNode.new(self._tree, self)
        self._numChildren += 1
    end
    return self._children[key] :: any
end

function TreeNode.RemoveChild<K, P>(self: TreeNode<K, P>, key: K): ()
    local child = self._children[key]
    if child then
        child:Deconstruct()
        self._children[key] = nil
        self._numChildren -= 1
    end
end

function TreeNode.SetValue<K, P>(self: TreeNode<K, P>, value: P): ()
    self._value = value
end

function TreeNode.GetValue<K, P>(self: TreeNode<K, P>): P?
    return self._value
end

function TreeNode.Deconstruct<K, P>(self: TreeNode<K, P>)
    -- Recursively deconstruct children
    for key, child in self._children do
        if child then
            child:Deconstruct()
            self._children[key] = nil
        end
    end

    -- Unlink from parent
    if self._parentNode then
        for key, child in self._parentNode._children do
            if child == self then
                self._parentNode:RemoveChild(key)
                break
            end
        end
    end

    -- Final cleanup
    self._children = {}
    self._value = nil
    self._numChildren = 0
    self._tree = nil :: any
    self._parentNode = nil :: any
end

return TreeNode
