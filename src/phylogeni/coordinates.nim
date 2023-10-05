import ./concepts, ./traverse

type
  CoordNode*[T] = ref object 
    parent: CoordNode[T]
    children: seq[CoordNode[T]]
    x: float # Horizontal position of node, equivalent to node height
    y: float # Vertical position of node
    node: T

proc parent*[T](n: CoordNode[T]): CoordNode[T] = 
  n.parent

proc children*[T](n: CoordNode[T]): seq[CoordNode[T]] = 
  n.children

proc x*[T](n: CoordNode[T]): float = 
  n.x

proc y*[T](n: CoordNode[T]): float = 
  n.x

proc node*[T](n: CoordNode[T]): T = 
  n.node

proc newCoordNode[T: TraversableNode](node: T): CoordNode[T] = 
  result = CoordNode[T](node: new(T)) 
  result.node[] = node[]  

proc addChild[T: TraversableNode](parent, child: CoordNode[T]) =  
  parent.children.add(child)
  child.parent = parent
  parent.node.children.add(child.node)
  child.node.parent = parent.node.parent
  # parent.node.addChild(child.node) # TODO: Use this when the proc for TraversableNode concept works

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