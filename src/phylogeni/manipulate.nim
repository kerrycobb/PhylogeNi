import ./concepts, ./traverse
import std/algorithm

export algorithm.SortOrder # Is this a bad practice? Is there an alternative?

# proc addChild(parent, child: TraversableNode) = 
# TODO: This causes an error, seems like a bug, reported https://github.com/nim-lang/Nim/issues/22723
#   parent.children.add(child)
#   child.parent = parent

func prune*(node: TraversableNode) =
  ## Prune branch from its tree.
  if node.parent == nil:
    raise newException(TreeError, "Cannot prune root node")
  var parent = node.parent
  parent.children.delete(parent.children.find(node))
  if parent.children.len() == 1:
    var child = parent.children[0]
    parent.children = child.children
    when node is LengthNode: 
      parent.length += child.length 
    when node is LabeledNode:
      parent.label = child.label

type
  LadderNode[T] = ref object
    parent: LadderNode[T] 
    children: seq[LadderNode[T]]
    descendants: int
    node: T

proc ladderize*[T: TraversableNode](root: T, order: SortOrder = Ascending) =
  ## Ladderize subtree.
  # Should benchmark this against hash approach, first figure out implementing hashes with concept
  # Could probably come up with more efficient way to sort using the current approach
  # Getting the index of the sorted children rather than the children would be simpler
  # and there wouldn't have to be a node attribute for LadderNode
  var currNode = LadderNode[T]()
  for i in root.newickorder:
    case i.state
    of ascendingTree:
      var newNode = LadderNode[T](parent:currNode, node:i.node)
      currNode.children.add(newNode)
      if not i.node.isLeaf:
        currNode = newNode
    of descendingTree: 
      # Sort children of LadderNode
      currNode.children.sort(cmp=func(a, b: LadderNode[T]): int = 
        cmp(a.descendants, b.descendants), order=order) 
      for ix, child in currNode.children:
        # Reorder node children 
        currNode.node.children[ix] = currNode.children[ix].node
        currNode.descendants += child.descendants
      currNode.descendants += currNode.children.len
      currNode = currNode.parent