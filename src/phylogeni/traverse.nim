import ./concepts
import std/algorithm

iterator preorder*(root: TraversableNode): TraversableNode =
  ## Preorder traverse of subtree.
  var stack = @[root]
  while stack.len > 0:
    var node = stack.pop()
    stack.add(node.children.reversed())
    yield node

iterator postorder*(root: TraversableNode): TraversableNode =
  ## Postorder traverse of subtree.
  var
    preStack = @[root]
    postStack: seq[TraversableNode]
  while preStack.len > 0:
    var node = preStack.pop() 
    postStack.add(node)
    preStack.add(node.children)
  while postStack.len > 0:
    var node = postStack.pop()
    yield node

iterator levelorder*(root: TraversableNode): TraversableNode =
  ## Levelorder traverse of subtree.
  yield root
  var stack = root.children 
  while stack.len > 0:
    var node = stack[0]
    stack.delete(0)
    yield node
    stack.add(node.children)

iterator iterleaves*(root: TraversableNode): TraversableNode =
  ## Iter over leaves of subtree.
  for i in root.preorder():
    if i.is_leaf():
      yield i

iterator iterAncestors*(node: TraversableNode): TraversableNode =
  var curr = node
  while true:
    if curr.parent != nil:
      yield curr.parent
      curr = curr.parent
    else:
      break


# TODO: Seems that there is a bug in Nim resulting in tuple causing error
# despite the code working. Revert to using tuple at some point to simplify this.
type
  AllorderDirection* = enum ascendingTree, descendingTree
    
  Allorder*[T: TraversableNode] = object
    node*: T 
    direction*: AllorderDirection 

func newAllorder[T](node: T, direction: AllorderDirection): Allorder[T] = 
  Allorder[T](node:node, direction:direction)

iterator allorder*[T: TraversableNode](root: T): Allorder[T] = 
# iterator allorder*[T](root: T): tuple[node:T, direction:AllorderDirection] =
  ## All order traverse. Combined preorder/postorder traverse. All leaf nodes 
  ## are visited once in preorder direction (Ascending). All internal nodes are 
  ## visited twice.
  var stack: seq[Allorder[T]]
  # var stack: seq[tuple[node: T, direction: AllorderDirection]]
  stack.add(newAllorder(root, descendingTree))
  stack.add(newAllorder(root, ascendingTree))
  # stack.add((root, descendingTree))
  # stack.add((root, ascendingTree))
  while stack.len > 0:
    var allorderNode = stack.pop() 
    yield allorderNode
    if not allorderNode.node.isLeaf:
      if allorderNode.direction == ascendingTree:
        let children = allorderNode.node.children 
        for i in countdown(children.len - 1 , 0):
          let child = children[i]
          if not child.isLeaf:
            stack.add(newAllorder(child, descendingTree))
            stack.add(newAllorder(child, ascendingTree))
            # stack.add((child, descendingTree))
            # stack.add((child, ascendingTree))
          else:
            stack.add(newAllorder(child, ascendingTree))
            # stack.add((child, ascendingTree))