--!strict

--// TYPES IMPORTS
local types = require(script.types)
local TreeNode = require(script.treeNode)

export type Tree<K, P> = types.Tree<K, P>
type TreeNode<K, P> = types.TreeNode<K, P>

local Tree = {}
Tree.__index = Tree

function Tree.new<K, P>(
    maxChildrenPerNode: number?,
    maxDepth: number?
): Tree<K, P>
    local self = setmetatable({}, Tree) :: Tree<K, P>
    self._maxChildrenPerNode = maxChildrenPerNode
    self._maxDepth = maxDepth
    self._head = TreeNode.new(self)
    return self
end

function Tree.GetNodeAt<K, P>(self: Tree<K, P>, ...: K): TreeNode<K, P>?
    local cur = self._head
    local keys = { ... }

    for _, key in keys do
        if not cur then break end
        cur = cur._children[key]
    end

    return cur
end

function Tree.SetValueAt<K, P>(self: Tree<K, P>, value: P, ...: K): ()
    local node = self._head
    local keys = { ... }

    for _, key in keys do
        local child = node._children[key]
        if child then
            node = child
        else
            node = node:AddChild(key)
        end
    end

    node:SetValue(value)
end

function Tree.GetValueAt<K, P>(self: Tree<K, P>, ...: K): P?
    local node = self:GetNodeAt(...)
    if not node then
        warn("No node found for path: " .. table.concat({ ... }, "."))
        return nil
    end

    return node:GetValue()
end

function Tree.Deconstruct<K, P>(self: Tree<K, P>)
    self._head:Deconstruct()
end

return Tree
