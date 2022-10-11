import algorithm, tables, hashes, strutils, sequtils

export algorithm.SortOrder 

type
  # NodeKind = enum nkLeaf, nkInner, nkRoot 

  # TODO: Rewrite like this once this is possible in Nim. 
  # See https://github.com/nim-lang/RFCs/issues/368 
  # Node*[T] = ref object 
  #   case kind: NodeKind
  #   of nkLeaf:
  #     parent*: Node[T]
  #   of nkInner:
  #     children*: seq[Node[T]]
  #     parent*: Node[T]
  #   of nkRoot:
  #     children*: seq[Node[T]]
  #   parent*: Node[T]
  #   label*: string
  #   length*: float
  #   data*: T

  Node*[T] = ref object
    parent*: Node[T]
    children*: seq[Node[T]]
    label*: string
    length*: float
    data*: T

  Tree*[T] = ref object
    root*: Node[T]
    rooted*: bool

  TreeError* = object of CatchableError

proc newTree*(typ: typedesc = void): Tree[typ] = Tree[typ]() 

proc newNode*(label: string, length: float, typ: typedesc = void): Node[typ] = 
  Node[typ](label:label, length:length) 

proc treeFromString*(str: string, typ: typedesc = void): Tree[typ] = 
  result = Tree[typ]()
  result.parseNewickString(str)

proc treeFromFile*(path: string, typ: typedesc = void): Tree[typ] = 
  result = Tree[typ]()
  result.parseNewickFile(path)

proc hash*[T](n: Node[T]): Hash =
  #TODO Data is not hashed
  #Use concept hashable
  result = n.label.hash !& n.length.hash
  result = !$result

proc addChild*[T](parent: Node[T], newChild: Node[T]) =
  ## Add child node to parent
  newChild.parent = parent
  parent.children.add(newChild)

proc addSister*[T](node: Node[T], newSister: Node[T]) =
  ## Add sister node
  newSister.parent = node.parent
  node.parent.children.add(newSister)

proc isLeaf*[T](node: Node[T]): bool =
  ## Check if node is leaf
  if node.children.len == 0:
    result = true
  else:
    result = false

proc prune*[T](tree: Tree[T], node: Node[T]) =
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

proc prune*[T](tree: Tree[T], nodes: seq[Node[T]]) =
  ## Prune nodes from tree
  for i in nodes:
    tree.prune(i)

iterator preorder*[T](root: Node[T]): Node[T] =
  ## Preorder traverse
  var stack = @[root]
  while stack.len > 0:
    var node = stack.pop()
    stack.add(node.children.reversed())
    yield node

iterator preorder*[T](tree: Tree[T]): Node[T] =
  ## Preorder traverse
  for i in tree.root.preorder():
    yield i

iterator postorder*[T](root: Node[T]): Node[T] =
  ## Postorder traverse
  var
    preStack = @[root]
    postStack: seq[Node[T]]
  while preStack.len > 0:
    var node = preStack.pop() 
    postStack.add(node)
    preStack.add(node.children)
  while postStack.len > 0:
    var node = postStack.pop()
    yield node
   
iterator postorder*[T](tree: Tree[T]): Node[T] =
  ## Postorder traverse
  for i in tree.root.postorder():
    yield i

iterator newickorder*[T](root: Node[T]): tuple[node:Node[T], firstVisit:bool] =
  ## Newick order traverse
  var stack: seq[tuple[node: Node[T], firstVisit: bool]]
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

iterator newickorder*[T](tree: Tree[T]): tuple[node:Node[T], firstVisit: bool] =
  ## Newick order traverse
  for i in tree.root.newickorder():
    yield i

iterator levelorder*[T](root: Node[T]): Node[T] =
  ## Levelorder traverse
  yield root
  var stack = root.children 
  while stack.len > 0:
    var node = stack[0]
    stack.delete(0)
    yield node
    stack.add(node.children)

iterator levelorder*[T](tree: Tree[T]): Node[T] =
  ## Levelorder traverse
  for i in tree.root.levelorder():
    yield i

iterator inorder*[T](root: Node[T]): Node[T] =
  ## Inorder traverse
  var
    stack: seq[Node[T]]
    current = root
  while current != nil or stack.len > 0:
    while current != nil:
      stack.add(current)
      if current.children.len == 2:
        current = current.children[0]
      elif current.children.len == 0:
        current = nil
      else:
        raise newException(TreeError, "Tree must be strictly bifurcating for inorder traverse")
    if stack.len > 0:
      var node = stack.pop()
      yield node
      if node.children.len == 2:
        current = node.children[1]
      elif node.children.len == 0:
        current = nil
      else:
        raise newException(TreeError, "Tree must be strictly bifurcating for inorder traverse")

iterator inorder*[T](tree: Tree[T]): Node[T] =  
  for i in tree.root.inorder():
    yield i

iterator iterleaves*[T](root: Node[T]): Node[T] =
  ## Iter over leaves
  for i in root.preorder():
    if i.is_leaf():
      yield i

iterator iterleaves*[T](tree: Tree[T]): Node[T] =
  ## Iter over leaves
  for i in tree.root.iterleaves():
    yield i

proc ladderize*[T](root: Node[T], order: SortOrder = Ascending) =
  ## Ladderize subtree
  # TODO: Should reimplement with heap queue
  var
    nodeDescendantCount = initTable[Node[T], int]()
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
          cmp=proc(a, b: Node[T]): int = cmp(nodeDescendantCount[b], 
          nodeDescendantCount[a]), order=order)

proc ladderize*[T](tree: Tree[T], order: SortOrder = Ascending) =
  ## Ladderize tree
  tree.root.ladderize(order)

proc calcTreeLength*[T](tree: Tree[T]): float =
  ## Calculate total length of tree
  var length = 0.0
  if tree.rooted:
    length += tree.root.length 
  for i in tree.preorder():
    length += i.length
  result = length

proc get_ascii[T](node: Node[T], char1="-", showInternal=true): tuple[clines: seq[string], mid:int] = 
  var 
    len = 3 
  if node.children.len == 0 or showInternal == true:
    if node.label.len > len:
      len = node.label.len
  var
    pad = strutils.repeat(' ', len)
    pa = strutils.repeat(' ', len-1)
  if node.children.len > 0:
    var 
      mids: seq[int] 
      results: seq[string]
    for child in node.children:
      var char2: string
      if node.children.len == 1:
        char2 = "-" 
      elif child == node.children[0]:
        char2 = "/"
      elif child == node.children[^1]:
        char2 = "\\"
      else:
        char2 = "-"
      var (clines, mid) = get_ascii(child, char2, showInternal)
      mids.add(mid+len(results))
      results.add(clines)
    var 
      lo = mids[0]
      hi = mids[^1]
      last = len(results)
      mid = int((lo+hi)/2)
      prefixes: seq[string] 
    prefixes.add(sequtils.repeat(pad, lo+1))
    if mids.len > 1:
      prefixes.add(sequtils.repeat(pa & "|", hi-lo-1))
    prefixes.add(sequtils.repeat(pad, last-hi))
    prefixes[mid] = char1 & strutils.repeat("-", len-2) & prefixes[mid][^1]
    var new_results: seq[string]  
    for (p, r) in zip(prefixes, results):
      new_results.add(p&r)
    if showInternal:
      var stem = new_results[mid]
      new_results[mid] = stem[0] & node.label & stem[node.label.len+1..^1]
    result = (new_results, mid) 
  else:
    result = (@[char1 & "-" & node.label], 0)

proc ascii*[T](node: Node[T], char1="-", showInternal=true): string = 
  var (lines, mid) = get_ascii(node, char1, showInternal) 
  result = lines.join("\n")

proc ascii*[T](tree: Tree[T], char1="-", showInternal=true): string = 
  var (lines, mid) = get_ascii(tree.root, char1, showInternal) 
  result = lines.join("\n")

proc `$`*[T](tree: Tree[T]): string =  
  result = ascii(tree.root) 

proc `$`*[T](node: Node[T]): string = 
  result = ascii(node) 



# TODO: Implement these:
# proc mrca*(tree: Tree, nodes: seq[Nodes]): Node =
  ## Return node of most recent common ancestor
 
# proc delete*(node: Node) = 
  ## Remove only this node and not parent or children
 
# proc extractTree*(node: Node): Tree =
  ## Returns rooted tree

# proc calcTreeHeight*(node: Node): float = 
  ## Calculatate length from node or root of tree to furthest leaf

# proc findName*(name: string): Node =

