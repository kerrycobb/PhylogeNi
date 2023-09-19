#TODO: Make Node attributes private and make setters and getters
# or make Node a concept

import std/[algorithm, tables, hashes, strutils, sequtils]

export algorithm.SortOrder 

type
  Node*[T] = ref object
    parent*: Node[T]
    children*: seq[Node[T]]
    label*: string
    length*: float
    data*: T

  TreeError* = object of CatchableError

func hash*[T](n: Node[T]): Hash =
  result = n.label.hash !& n.length.hash
  result = !$result

func addChild*[T](parent: Node[T], newChild: Node[T]) =
  ## Add child node to parent.
  newChild.parent = parent
  parent.children.add(newChild)

func addSister*[T](node: Node[T], newSister: Node[T]) =
  ## Add sister node.
  newSister.parent = node.parent
  node.parent.children.add(newSister)

func isLeaf*[T](node: Node[T]): bool =
  ## Check if node is leaf.
  if node.children.len == 0:
    result = true
  else:
    result = false

func isRoot*[T](node: Node[T]): bool =
  if node.parent == nil:
    result = true
  else:
    result = false

func prune*[T](tree, node: Node[T]) =
  ## Prune branch leading to node from tree.
  if node.parent == nil:
    raise newException(TreeError, "Cannot prune root node")
  var parent = node.parent
  parent.children.delete(parent.children.find(node))
  if parent.children.len() == 1:
    var child = parent.children[0]
    parent.length += child.length 
    parent.children = child.children
    parent.label = child.label

proc copyTree*[T](tree: Node[T], typ: typedesc = void): Node[typ] = 
  ## Copy the structure, edge lengths, and labels of a tree. The returned tree 
  ## may have a different data type.
  var copied = Node[typ](length:tree.length, label:tree.label)  
  for i in tree.children:
    copied.addChild(copyTree(i, typ))
  result = copied

iterator preorder*[T](root: Node[T]): Node[T] =
  ## Preorder traverse.
  var stack = @[root]
  while stack.len > 0:
    var node = stack.pop()
    stack.add(node.children.reversed())
    yield node

iterator postorder*[T](root: Node[T]): Node[T] =
  ## Postorder traverse.
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
   
iterator newickorder*[T](root: Node[T]): tuple[node:Node[T], firstVisit:bool] =
  ## Newick order traverse. All internal nodes are visited twice.
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

iterator levelorder*[T](root: Node[T]): Node[T] =
  ## Levelorder traverse.
  yield root
  var stack = root.children 
  while stack.len > 0:
    var node = stack[0]
    stack.delete(0)
    yield node
    stack.add(node.children)

iterator iterleaves*[T](root: Node[T]): Node[T] =
  ## Iter over leaves.
  for i in root.preorder():
    if i.is_leaf():
      yield i

func ladderize*[T](root: Node[T], order: SortOrder = Ascending) =
  ## Ladderize subtree.
  # TODO: Should reimplement with heap queue and without using table 
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
          cmp=func(a, b: Node[T]): int = cmp(nodeDescendantCount[b], 
          nodeDescendantCount[a]), order=order)

func calcTreeLength*[T](node: Node[T]): float =
  ## Calculate total length of tree.
  result = 0.0
  for child in node.children:
    for i in child.preorder(): 
      result += i.length 

func treeHeight*[T](node: Node[T]): float = 
  ## Calculate the height of subtree. 
  var maxHeight = 0.0
  for child in node.children:
    let childHeight = treeHeight(child)
    maxHeight = max(maxHeight, childHeight) 
  result = maxHeight + node.length

func findNode*[T](tree: Node[T], str: string): Node[T] = 
  ## Returns first instance of node label matching str.
  for i in tree.preorder: 
    if i.label == str:
      return i

func getAncestors*[T](node: Node[T]): seq[Node[T]] =
  var curr = node
  while true:
    if curr.parent != nil:
      result.add(curr.parent)
      curr = curr.parent
    else:
      break

func getMRCA*[T](a, b: Node[T]): Node[T] = 
  ## Get the most recent common ancestor of two nodes.
  # TODO: I think this could be faster adding the elements of the shoter list to a 
  # hash set and then checking if the elements of the other list belong to that set
  let 
    aAncestors = a.getAncestors
    bAncestors = b.getAncestors
  for i in aAncestors:
    for j in bAncestors:
      if i == j:
        return i
  raise newException(TreeError, "No MRCA shared by nodes")

func get_ascii[T](node: Node[T], char1="-", showInternal=true): tuple[clines: seq[string], mid:int] = 
  ## Generates ascii string representation of tree.
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

func ascii*[T](node: Node[T], char1="-", showInternal=true): string = 
  ## Returns ascii string representation of tree.
  var (lines, _) = get_ascii(node, char1, showInternal) 
  result = lines.join("\n")

func `$`*[T](node: Node[T]): string = 
  result = node.label

# TODO: Implement these:
# func delete*(node: Node) = 
  ## Remove only this node and not parent or children
 
# func extractTreeCopy*[T](node: Node[T]): Node[T] =
  # Return copy of tree rooted at node.