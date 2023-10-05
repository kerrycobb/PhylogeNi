import std/[strutils, sequtils]

type
  TreeError* = object of CatchableError

type
  TraversableNode*  = concept n, type T 
    n.parent is T
    for i in n.children:
      i is T

func isLeaf*(node: TraversableNode): bool =
  ## Check if node is leaf.
  if node.children.len == 0:
    result = true
  else:
    result = false

func isRoot*(node: TraversableNode): bool = 
  if node.parent.isNil:
    result = true
  else:
    result = false

proc mrca*(a, b: TraversableNode): TraversableNode = 
  ## Get the most recent common ancestor of two nodes.
  for i in a.iterAncestors:
    for j in b.iterAncestors:
      if i == j:
        return i
  raise newException(TreeError, "No MRCA shared by nodes")


###############################
# Labeled Node
type
  LabeledNode* = concept n 
    n is TraversableNode 
    n.label is string

func find*(tree: LabeledNode, str: string): LabeledNode = 
  ## Returns first instance of node label matching str.
  for i in tree.preorder: 
    if i.label == str:
      return i

func `$`*(node: LabeledNode): string = 
  node.label

func get_ascii(node: LabeledNode, char1="-", showInternal=true): tuple[clines: seq[string], mid:int] = 
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

func ascii*(node: LabeledNode, char1="-", showInternal=true): string = 
  ## Returns ascii string representation of tree.
  var (lines, _) = get_ascii(node, char1, showInternal) 
  result = lines.join("\n")


###############################
# Length Node
type
  LengthNode* = concept n 
    n is TraversableNode 
    n.length is SomeNumber 

func calcTreeLength*(node: LengthNode): float =
  ## Calculate total length of tree.
  result = 0.0
  for child in node.children:
    for i in child.preorder(): 
      result += i.length 

func treeHeight*(node: LengthNode): float = 
  ## Calculate the height of subtree. 
  var maxHeight = 0.0
  for child in node.children:
    let childHeight = treeHeight(child)
    maxHeight = max(maxHeight, childHeight) 
  result = maxHeight + node.length


###############################
# Data readable from Newick string 
type
  ReadableDataNode* = concept n
    n is TraversableNode
    n.parseNewickData(string)


###############################
# Data writable to Newick string 
type
  WritableDataNode* = concept n
    n is TraversableNode
    n.writeNewickData is string