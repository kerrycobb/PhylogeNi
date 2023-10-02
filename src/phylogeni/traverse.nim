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

type
  NewickOrderState* = enum 
    ascendingTree, descendingTree
    
  NewickOrderNode*[T: TraversableNode] = ref object
    node*: T 
    state*: NewickOrderState 

func newNewickOrderNode[T](node: T, state: NewickOrderState): NewickOrderNode[T] = 
  NewickOrderNode[T](node:node, state:state)

func children*[T](node: NewickOrderNode[T]): seq[T] = 
  node.node.children

func parent*[T](node: NewickOrderNode[T]): T =
  node.node.parent

func isLeaf*[T](node: NewickOrderNode[T]): bool = 
  ## Check if node is leaf.
  node.node.isLeaf

func isRoot*[T](node: NewickOrderNode[T]): bool =
  node.node.isRoot

proc `$`*[T](node: NewickOrderNode[T]): string = 
  $node.node & ", " & $node.state  

iterator newickorder*[T: TraversableNode](root: T): NewickOrderNode[T] = 
  ## Newick order traverse. All internal nodes are visited twice. Leaf nodes are
  ## only visited once. This traverese is a hybrid between preorder and 
  ## postorder traverse. It is convenient for writing newick strings and 
  ## plotting trees.
  var stack: seq[NewickOrderNode[T]]
  stack.add(newNewickOrderNode(root, descendingTree))
  stack.add(newNewickOrderNode(root, ascendingTree))
  while stack.len > 0:
    var node = stack.pop() 
    yield node
    if not node.isLeaf:
      if node.state == ascendingTree:
        for child in node.children.reversed:
          if not child.isLeaf:
            stack.add(newNewickOrderNode(child, descendingTree))
            stack.add(newNewickOrderNode(child, ascendingTree))
          else:
            stack.add(newNewickOrderNode(child, ascendingTree))
