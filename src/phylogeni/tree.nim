import algorithm, tables, hashes

# TODO: Add more error checks and exceptions 
# TODO: Inorder traversal
# TODO: Procs to remove nodes and subtrees

type
  Node* = ref object
    parent*: Node
    children*: seq[Node]
    name*: string
    length*: float

  Tree* = ref object
    root*: Node
    rooted*: bool

  TreeError = object of CatchableError

proc newNode*(): Node =
  new(result)

proc newTree*(): Tree =
  new(result)

proc hash*(n: Node): Hash =
  result = n.name.hash !& n.length.hash
  result = !$result

proc addChild*(parent, newChild: Node) =
  ## Add child node to parent
  newChild.parent = parent
  parent.children.add(newChild)

proc addSister*(node, newSister: Node) =
  ## Add sister node
  newSister.parent = node.parent
  node.parent.children.add(newSister)

proc isLeaf*(node: Node): bool =
  ## Check if node is leaf
  if node.children.len == 0:
    result = true
  else:
    result = false

proc prune*(tree: Tree, node: Node) =
  ## Prune node from tree
  var parent = node.parent
  if node == tree.root:
    raise newException(TreeError, "Cannot prune root node")
  parent.children.delete(parent.children.find(node))
  if parent.children.len() == 1:
    var child = parent.children[0]
    child.length += parent.length
    if parent == tree.root:
      child.parent = nil
      tree.root = child
    else:
      var grandparent = parent.parent
      child.parent = grandparent
      grandparent.children[grandparent.children.find(parent)] = child

proc prune*(tree: Tree, nodes: seq[Node]) =
  ## Prune nodes from tree
  for i in nodes:
    tree.prune(i)

iterator preorder*(root: Node): Node =
  ## Preorder traverse
  var stack = @[root]
  while stack.len > 0:
    var node = stack.pop()
    stack.add(node.children.reversed())
    yield node

iterator preorder*(tree: Tree): Node =
  ## Preorder traverse
  for i in tree.root.preorder():
    yield i

iterator postorder*(root: Node): Node =
  ## Postorder traverse
  var
    preStack = @[root]
    postStack: seq[Node]
  while preStack.len > 0:
    var node = preStack.pop() 
    postStack.add(node)
    preStack.add(node.children)
  while postStack.len > 0:
    var node = postStack.pop()
    yield node
   
iterator postorder*(tree: Tree): Node =
  ## Postorder traverse
  for i in tree.root.postorder():
    yield i

iterator newickorder*(root: Node): tuple[node:Node, firstVisit:bool] =
  ## Newick order traverse
  var stack: seq[tuple[node: Node, firstVisit: bool]]
  stack.add((node: root, firstVisit: false))
  stack.add((node: root, firstVisit: true))
  while stack.len > 0:
    var nodeTuple = stack.pop()
    yield (nodeTuple)
    if nodeTuple.node.children.len > 0:
      if nodeTuple.firstVisit == true:
        for child in nodeTuple.node.children.reversed:
          if child.children.len > 0:
              stack.add((child, false))
              stack.add((child, true))
          else:
            stack.add((child, true))

iterator newickorder*(tree: Tree): tuple[node:Node, firstVisit: bool] =
  ## Newick order traverse
  for i in tree.root.newickorder():
    yield i

iterator levelorder*(root: Node): Node =
  ## Levelorder traverse
  yield root
  var stack = root.children
  while stack.len > 0:
    var node = stack[0]
    stack.delete(0)
    yield node
    stack.add(node.children)

iterator levelorder*(tree: Tree): Node =
  ## Levelorder traverse
  for i in tree.root.levelorder():
    yield i

iterator iterleaves*(root: Node): Node =
  ## Iter over leaves
  for i in root.preorder():
    if i.is_leaf():
      yield i

iterator iterleaves*(tree: Tree): Node =
  ## Iter over leaves
  for i in tree.root.iterleaves():
    yield i

proc ladderize*(root: Node, ascending: bool = true) =
  ## Ladderize subtree
  var
    nodeDescendantCount = initTable[Node, int]()
    order: SortOrder
  if ascending:
    order = Ascending
  for node in root.postorder():
    if node.children.len == 0:
      nodeDescendantCount[node] = 0
    else:
      var total = 0
      for child in node.children:
        total += nodeDescendantCount[child]
      total += node.children.len
      nodeDescendantCount[node] = total
      node.children.sort(
          cmp=proc(a, b: Node): int = cmp(nodeDescendantCount[a], 
          nodeDescendantCount[b]), order=order)

proc ladderize*(tree: Tree, ascending: bool = true) =
  ## Ladderize tree
  tree.root.ladderize(ascending=ascending)

proc calcTreeLength*(tree: Tree): float =
  # TODO: Include root if tree is rooted
  ## Calculate total length of tree
  var length = 0.0
  for i in tree.preorder():
    length += i.length
  result = length


# TODO: Implement these:
# proc mrca*(tree: Tree, nodes: seq[Nodes]): Node =
  ## Return node of most recent common ancestor
# proc treeHeight*(node: Node) =
# proc extractTree*(node: Node): Tree =
  ## Returns rooted tree
# proc findName*(name: string): Node =
# proc maxDist*(tree: Tree): float =
# proc midpointRoot*(tree: Tree) = 
# proc rootOnOutgroup*(tree: Tree, node: Node) = 
# proc prune_regraft*():
# proc subtree_swap*():
# proc subtree_prune_regraft*():
# proc fixed_nodeheight_prune_regraft*():