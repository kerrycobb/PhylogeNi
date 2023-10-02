# import system
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

# func getAncestors*(node: TraversableNode): seq[TraversableNode] =
#   # TODO: Not working
#   var curr = node
#   while true:
#     if curr.parent != nil:
#       result.add(curr.parent)
#       curr = curr.parent
#     else:
#       break

proc getMRCA*(a, b: TraversableNode): TraversableNode = 
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
# 
type
  ReadableDataNode* = concept n
    n is TraversableNode
    n.parseNewickData(string)

type
  WritableDataNode* = concept n
    n is TraversableNode
    n.writeNewickData is string

# TODO: would this be redundant?
# TODO: could it improve clarity?
# For use by procs in manipulate module
# type 
#   MutableNode* = concept n
#     n is TraversableNode
#     n.parent #TODO: how to confirm if this is mutable 
#     n.children # TODO: how to confirm that this is mutable 



















# TODO: Delete everything below eventually, make sure everythnig was copied somewhere else
# import std/algorithm
# import std/strutils
# import std/sequtils
# import system

# #############################################################
# # Iterable Node
# type
#   TraversableNode*  = concept n, type T 
#     n.parent is T
#     for i in n.children:
#       i is T

# # TODO: This causes an error, seems like a bug, reported https://github.com/nim-lang/Nim/issues/22723
# # proc addChild(parent, child: TraversableNode) = 
# #   parent.children.add(child)
# #   child.parent = parent

# func isLeaf*(node: TraversableNode): bool =
#   ## Check if node is leaf.
#   if node.children.len == 0:
#     result = true
#   else:
#     result = false

# func isRoot*(node: TraversableNode): bool = 
#   if node.parent.isNil:
#     result = true
#   else:
#     result = false

# iterator preorder*(root: TraversableNode): TraversableNode =
#   ## Preorder traverse.
#   var stack = @[root]
#   while stack.len > 0:
#     var node = stack.pop()
#     stack.add(node.children.reversed())
#     yield node

# iterator postorder*(root: TraversableNode): TraversableNode =
#   ## Postorder traverse.
#   var
#     preStack = @[root]
#     postStack: seq[TraversableNode]
#   while preStack.len > 0:
#     var node = preStack.pop() 
#     postStack.add(node)
#     preStack.add(node.children)
#   while postStack.len > 0:
#     var node = postStack.pop()
#     yield node

# iterator levelorder*(root: TraversableNode): TraversableNode =
#   ## Levelorder traverse.
#   yield root
#   var stack = root.children 
#   while stack.len > 0:
#     var node = stack[0]
#     stack.delete(0)
#     yield node
#     stack.add(node.children)

# iterator iterleaves*(root: TraversableNode): TraversableNode =
#   ## Iter over leaves.
#   for i in root.preorder():
#     if i.is_leaf():
#       yield i

# # NewickOrder Iterator
# type
#   NewickOrderState* = enum 
#     ascendingTree, descendingTree
    
#   NewickOrderNode*[T: TraversableNode] = ref object
#     node*: T 
#     state*: NewickOrderState 

# func newNewickOrderNode[T](node: T, state: NewickOrderState): NewickOrderNode[T] = 
#   NewickOrderNode[T](node:node, state:state)

# func children*[T](node: NewickOrderNode[T]): seq[T] = 
#   node.node.children

# func parent*[T](node: NewickOrderNode[T]): T =
#   node.node.parent

# func isLeaf*[T](node: NewickOrderNode[T]): bool = 
#   ## Check if node is leaf.
#   node.node.isLeaf

# func isRoot*[T](node: NewickOrderNode[T]): bool =
#   node.node.isRoot

# proc `$`*[T](node: NewickOrderNode[T]): string = 
#   $node.node & ", " & $node.state  

# iterator newickorder*[T: TraversableNode](root: T): NewickOrderNode[T] = 
#   ## Newick order traverse. All internal nodes are visited twice. Leaf nodes are
#   ## only visited once. This traverese is a hybrid between preorder and 
#   ## postorder traverse. It is convenient for writing newick strings and 
#   ## plotting trees.
#   var stack: seq[NewickOrderNode[T]]
#   stack.add(newNewickOrderNode(root, descendingTree))
#   stack.add(newNewickOrderNode(root, ascendingTree))
#   while stack.len > 0:
#     var node = stack.pop() 
#     yield node
#     if not node.isLeaf:
#       if node.state == ascendingTree:
#         for child in node.children.reversed:
#           if not child.isLeaf:
#             stack.add(newNewickOrderNode(child, descendingTree))
#             stack.add(newNewickOrderNode(child, ascendingTree))
#           else:
#             stack.add(newNewickOrderNode(child, ascendingTree))


# ################################################################
# # Length Node
# type
#   LengthNode = concept n 
#     n is TraversableNode 
#     n.length is SomeNumber 

# type
#   ReadableAnnotatedNode = concept n
#     n is TraversableNode
#     n.parseAnnotation(string)

# type
#   WritableAnnotatedNode = concept n
#     n is TraversableNode
#     n.writeAnnotation is string



# ################################################################
# # Labelled Node
# type
#   LabelledNode = concept n 
#     n is TraversableNode 
#     n.label is string

# func `$`*(node: LabelledNode): string = 
#   node.label

# func get_ascii(node: LabelledNode, char1="-", showInternal=true): tuple[clines: seq[string], mid:int] = 
#   ## Generates ascii string representation of tree.
#   var 
#     len = 3 
#   if node.children.len == 0 or showInternal == true:
#     if node.label.len > len:
#       len = node.label.len
#   var
#     pad = strutils.repeat(' ', len)
#     pa = strutils.repeat(' ', len-1)
#   if node.children.len > 0:
#     var 
#       mids: seq[int] 
#       results: seq[string]
#     for child in node.children:
#       var char2: string
#       if node.children.len == 1:
#         char2 = "-" 
#       elif child == node.children[0]:
#         char2 = "/"
#       elif child == node.children[^1]:
#         char2 = "\\"
#       else:
#         char2 = "-"
#       var (clines, mid) = get_ascii(child, char2, showInternal)
#       mids.add(mid+len(results))
#       results.add(clines)
#     var 
#       lo = mids[0]
#       hi = mids[^1]
#       last = len(results)
#       mid = int((lo+hi)/2)
#       prefixes: seq[string] 
#     prefixes.add(sequtils.repeat(pad, lo+1))
#     if mids.len > 1:
#       prefixes.add(sequtils.repeat(pa & "|", hi-lo-1))
#     prefixes.add(sequtils.repeat(pad, last-hi))
#     prefixes[mid] = char1 & strutils.repeat("-", len-2) & prefixes[mid][^1]
#     var new_results: seq[string]  
#     for (p, r) in zip(prefixes, results):
#       new_results.add(p&r)
#     if showInternal:
#       var stem = new_results[mid]
#       new_results[mid] = stem[0] & node.label & stem[node.label.len+1..^1]
#     result = (new_results, mid) 
#   else:
#     result = (@[char1 & "-" & node.label], 0)

# func ascii*(node: LabelledNode, char1="-", showInternal=true): string = 
#   ## Returns ascii string representation of tree.
#   var (lines, _) = get_ascii(node, char1, showInternal) 
#   result = lines.join("\n")


# #####################################################
# # Writing Newick String

# func writeNewickData(node: TraversableNode, str: var string, annotation: bool) =
#   when typeof(node) is LabelledNode:
#     str.add(node.label)
#   when typeof(node) is LengthNode: 
#     str.add(':')
#     str.add($node.length)
#   when typeof(node) is WritableAnnotatedNode:
#     if annotation:
#       str.add(node.writeAnnotation)

# func writeNewickString*(root: TraversableNode, annotation=true): string =
#   ## Write newick string for Node object
#   var str = ""
#   for i in root.newickorder():
#     if i.state == ascendingTree:
#       if i.node.isLeaf():
#         i.node.writeNewickData(str, annotation)
#         if i.node != i.parent.children[^1]: # not the first node in parents children
#           str.add(",")
#       else: # internal node
#         str.add("(")
#     else: # descending tree 
#       str.add(")")
#       i.node.writeNewickData(str, annotation)
#       if (i.node != root) and (i.node != i.parent.children[^1]): # not last node in parents children
#         str.add(",")
#   str.add(";")
#   result = str

# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# # Parse Newick

# import std/[streams, lexbase, strformat, strutils]

# type 
#   NewickError* = object of IOError

#   NewickState = enum
#     newickStart, newickTopology, newickLabel, newickLength, newickAnnotation,
#     newickEnd, newickEOF
#     # TODO: This might be a better way to track state in order to raise errors if
#     # a newick string doesn't have any parentheses. Low priority given how 
#     # unlikely that is. 
#     # newickStart, newickStartLabel, newickStartLength, newickStartTopology, 
#     # newickTopology, newickLabel, newickLength, newickEnd, newickEOF
  
#   NewickParser[T: TraversableNode] = object of BaseLexer
#     root: T 
#     currNode: T 
#     token: string 
#     state: NewickState
#     annotationState: bool # False if an annotation has already been parsed 

# const newickWhitespace = {' ', '\t', '\c', '\l'}

# proc raiseError(p: NewickParser, msg: string) = 
#   var 
#     lineNum = $p.lineNumber 
#     colNum = $p.getColNumber(p.bufpos+1)
#     m = fmt"{msg} at line {lineNum}, column {colNum}"
#   raise newException(NewickError, m)

# proc parseWhitespace(p: var NewickParser, skip=true) = 
#   while true:
#     case p.buf[p.bufpos]
#     of ' ', '\t':
#       if not skip: p.token.add(p.buf[p.bufpos])
#       p.bufpos.inc()
#     of '\c':
#       if not skip: p.token.add(p.buf[p.bufpos])
#       p.bufpos = lexbase.handleCR(p, p.bufpos)
#     of '\l': # same as \n
#       if not skip: p.token.add(p.buf[p.bufpos])
#       p.bufpos = lexbase.handleLF(p, p.bufpos)
#     else:
#       break

# # # proc parseAnnotation(p: var NewickParser[string], annotation: string) =  
# # #   p.currNode.data = annotation

# # # proc parseAnnotation(p: var NewickParser[void], annotation: string) = 
# # #   discard

# proc parseBracket(p: var NewickParser, showComments=false) = 
#   # TODO: handle unexpected end of file and newick statement
#   mixin parseAnnotation
#   p.token = ""
#   p.bufpos.inc()
#   while true:
#     case p.buf[p.bufpos]
#     of ']':
#       p.bufpos.inc()
#       break
#     of newickWhitespace:
#       p.parseWhitespace(skip=false)
#     else:
#       p.token.add(p.buf[p.bufpos])
#       p.bufpos.inc()
#   if p.token.startswith('&'):
#     if p.annotationState:
#       # p.parseAnnotation(p.token[1..^1])
#       p.annotationState = false
#   else:
#     if showComments:
#       echo p.token 

# proc parseLength(p: var NewickParser) =     
#   #TODO: Determine if length is float or int for nodetype and convert string appropriately
#   var parseLength = true
#   while true:
#     case p.buf[p.bufpos]
#     of '(', ',', ')', ';':
#       p.state = newickTopology
#       break
#     of newickWhitespace: 
#       p.parseWhitespace()
#     of '[':
#       # p.parseBracket()
#       p.state = newickAnnotation
#       break
#     of EndOfFile:
#       p.raiseError("Unexpected end of stream")
#     else:
#       if parseLength:
#         p.token = ""
#         while true:
#           case p.buf[p.bufpos]
#           of '(', ',', ')', ';', '[', newickWhitespace, EndOfFile:
#             parseLength = false
#             break
#           of '"':
#             p.raiseError("Unexpected \"") 
#           else:
#             p.token.add(p.buf[p.bufpos])
#             p.bufpos.inc()
#         p.currNode.length = parseFloat(p.token)
#         parseLength = false

# proc parseLabel(p: var NewickParser) = 
#   # TODO: Write when statement to determine if node has label property
#   var parseLabel = true
#   p.annotationState = true
#   while true:
#     case p.buf[p.bufpos]
#     of '(', ',', ')', ';':
#       p.state = newickTopology
#       break
#     of ':':
#       p.state = newickLength
#       p.bufpos.inc()
#       break
#     of '[':
#       p.state = newickAnnotation
#       break
#     #   p.parseBracket()
#     of newickWhitespace:
#       p.parseWhitespace()
#     of EndOfFile:
#       p.raiseError("Unexpected end of stream")
#     of '"':
#       # Parse quoted text
#       if parseLabel:        
#         p.token = ""
#         p.bufpos.inc()
#         while true:
#           case p.buf[p.bufpos]
#           of '"': 
#             p.bufpos.inc()
#             break
#           of newickWhitespace: 
#             p.parseWhitespace(skip=false)
#           else:
#             p.token.add(p.buf[p.bufpos])
#             p.bufpos.inc()
#         p.currNode.label = p.token
#         parseLabel = false
#       else: 
#         p.raiseError("Unexpected \"")
#     else:
#       # Parse unquoted text
#       if parseLabel:
#         p.token = ""
#         while true:
#           case p.buf[p.bufpos]
#           of '(', ',', ')', ';', ':', '[', ']', newickWhitespace, EndOfFile:
#             parseLabel = false
#             break
#           of '"':
#             p.raiseError("Unexpected \"") 
#           else:
#             p.token.add(p.buf[p.bufpos])
#             p.bufpos.inc()
#         p.currNode.label = p.token
#         parseLabel = false
#       else:
#         p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 

# proc parseData(p: var NewickParser) = 
#   var annotation = ""
#   p.bufpos.inc
#   while true:
#     case p.buf[p.bufpos] 
#     of ']':
#       p.state = newickTopology
#       p.bufpos.inc()
#       break
#     else:
#       annotation.add(p.buf[p.bufpos])
#       p.bufpos.inc()
#   # TODO: Call annotation function if Node is annotabale
#   when typeof(p.currNode) is ReadableAnnotatedNode:
#     p.currNode.parseAnnotation(annotation)

# proc parseTopology(p: var NewickParser, T: typedesc[TraversableNode]) = 
#   # Parse newick tree 
#   case p.buf[p.bufpos]
#   of '(':
#     var newNode = new(T)
#     p.currNode.addChild(newNode)
#     p.currNode = newNode
#     p.bufpos.inc()
#     p.state = newickLabel
#   of ',':
#     var newNode = new(T)
#     p.currNode.parent.addChild(newNode)
#     p.currNode = newNode
#     p.bufpos.inc()
#     p.state = newickLabel
#   of ')':
#     p.currNode = p.currNode.parent
#     p.bufpos.inc()
#     p.state = newickLabel
#   of ';':
#     if p.currNode == p.root:
#       p.bufpos.inc()
#       p.state = newickEnd
#     else:
#       p.raiseError("Mismatched parentheses") 
#   else:
#     p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 

# proc parseStart(p: var NewickParser) = 
#   # Parse beginning of newick file
#   while true:
#     case p.buf[p.bufpos]
#     of '(':
#       p.state = newickTopology
#       break
#     of newickWhitespace:
#       p.parseWhitespace()
#     of '[':
#       if p.buf[p.bufpos+1] == '&':
#         case p.buf[p.bufpos+2]
#         of 'r', 'R': 
#           discard
#         of 'u', 'U':
#           discard
#         else:
#           p.bufpos.inc(2)
#           p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 
#         if p.buf[p.bufpos+3] == ']':
#           p.bufpos.inc(4)
#         else:
#           p.bufpos.inc(3)
#           p.raiseError("Expected \"]\"")
#       else:
#         p.parseBracket()
#     of EndOfFile:
#       # p.state = newickEOF
#       # break
#       p.raiseError("Unexpected end of file. No newick statment found.")
#     else:
#       p.state = newickLabel
#       break

# proc parseTree(p: var NewickParser, T: typedesc[TraversableNode]) = 
#   p.parseWhitespace()
#   while true:
#     case p.state
#     of newickStart:
#       p.parseStart()
#     of newickTopology:
#       p.parseTopology(T)
#     of newickLabel: 
#       p.parseLabel()
#     of newickLength:
#       p.parseLength()
#     of newickAnnotation:
#       p.parseData()
#     of newickEnd:
#       break
#     of newickEOF:
#       break

# proc parseNewickStream*(stream: Stream, T: typedesc[TraversableNode]): T =
#   ## Parse a newick stream
#   var
#     p = NewickParser[T]()
#   p.root = new(T)
#   p.currNode = p.root
#   p.open(stream)
#   p.parseTree(T)
#   p.close()
#   result = p.root 

# proc parseNewickString*(str: string, T: typedesc[TraversableNode]): T =
#   ## Parse a newick string
#   var ss = newStringStream(str)
#   result = parseNewickStream(ss, T) 
#   ss.close()


# #############################################
# # Drawing 

# type
#   CoordNode*[T] = ref object 
#     parent: CoordNode[T]
#     children: seq[CoordNode[T]]
#     x: float # Horizontal position of node, equivalent to node height
#     y: float # Vertical position of node
#     node: T

# proc newCoordNode[T: TraversableNode](node: T): CoordNode[T] = 
#   result = CoordNode[T](node: new(T)) 
#   result.node[] = node[]  

# proc addChild[T: TraversableNode](parent, child: CoordNode[T]) =  
#   parent.children.add(child)
#   child.parent = parent
#   parent.node.children.add(child.node)
#   child.node.parent = parent.node.parent
#   # parent.node.addChild(child.node) # TODO: Use this when the proc for TraversableNode concept works

# proc getCoords*[T: LengthNode](root: T, branchLengthScaling=1.0, branchSep=1.0): CoordNode[T] = 
#   ## Return coordinates for a typical rectangular or slanted phylogeny
#   assert branchLengthScaling > 0
#   assert branchSep > 0
#   var 
#     leafY = 0.0
#     currNode = CoordNode[T](node: new(T)) # Placeholder, is parent to root node of new tree
#   for i in root.newickorder:
#     case i.state
#     of ascendingTree:
#       var newNode = newCoordNode(i.node)
#       currNode.addChild(newNode)
#       newNode.x = currNode.x + (i.node.length * branchLengthScaling)
#       if i.node.isLeaf:
#         newNode.y = leafY
#         leafY += branchSep
#       else:
#         currNode = newNode
#     of descendingTree: 
#       let 
#         lo = currNode.children[0].y
#         up = currNode.children[^1].y
#       currNode.y = (up - lo) / 2 + lo
#       currNode = currNode.parent
#   result = currNode.children[0]


# #############################################
# # Testing

# type
#   Nd = ref object
#     parent: Nd 
#     children: seq[Nd]
#     label: string
#     length: float
#     data: string

# proc addChild(parent, child: Nd) = 
#   # TODO: Make this a concept once that works 
#   parent.children.add(child)
#   child.parent = parent

# proc writeAnnotation(node: Nd): string = 
#   result.add('[')
#   result.add(node.data)
#   result.add(']')

# proc parseAnnotation(node: Nd, str: string) = 
#   node.data = str



# var t = parseNewickString("(b:1.0,(d:1.0,(f:1.0,g:1.0)e:1.0)c:1.0)a:1.0;", Nd)
# echo t.writeNewickString(false)

# # Bad newick strings
# # TODO: Fix parser to catch these and raise exception with helpful error msg
# # var 
#   # str = "(B:1.0, [test]C:1.0)A:1.0;" #TODO: Fix error msg
#   # str = "(B:1.0,C:[test]1.0)A:1.0;" #TODO: Fix error msg
#   # str = "(B:1.0,C:1.0:[test])A:1.0;" #TODO: Fix error msg
#   # str = "B:1.0,C:1.0:[test])A:1.0;" #TODO: Fix error msg
#   # t = parseNewickString(str, Nd)

# echo t.ascii

# var c = t.getCoords()
# for i in c.preorder:
#   echo i[]






# # 
