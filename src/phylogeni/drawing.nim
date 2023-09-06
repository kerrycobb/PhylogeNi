import ./tree

import phylogeni

type
  DrawNode*[T] = ref object
    x: float # Horizontal position of node, equivalent to node height
    y: float # Vertical position of node
    data: T 

template toClosure*(i): auto =
  ## Wrap an inline iterator in a first-class closure iterator.
  iterator j: type(i) {.closure.} =
    for x in i: yield x
  j

proc copyToDrawNodeTree[T](tree: Node[T]): Node[DrawNode[T]] = 
  ## Copy tree structure and replace existing data with DrawNode type with 
  ## data being copied to the DrawNode data property
  var copied = Node[DrawNode[T]](length:tree.length, label:tree.label, data:DrawNode[T](data:tree.data))  
  for i in tree.children:
    copied.addChild(copyToDrawNodeTree(i))
  result = copied

proc getCoords*[T](tree: Node[T], branchLengthScaling=1.0, branchSepScaling=1.0): Node[DrawNode[T]] =
  ## Return coordinates for a typical rectangular or slanted phylogeny
  # TODO: Raise Error if branchLengthScaling or branchSepScaling is <=0
  var copied = copyToDrawNodeTree(tree)  

  # Make newickorder a closure iterator using template
  let newickOrderIt = toClosure(copied.newickorder)

  # Iter over nodes in newick order. Assign x on first pass of all nodes.
  # Assign y when visiting leaves and second visit of each node.
  var 
    root = newickOrderIt().node
    leafY = 0.0
  root.data = DrawNode[T]()
  root.data.x = root.length * branchSepScaling
  for i in newickOrderIt():
    var n = i.node 
    if i.firstVisit:
      # Assign x on first visit
      n.data.x = n.parent.data.x + (n.length * branchLengthScaling)
      # Assign y to leaves
      if i.node.isLeaf:
        n.data.y = leafY
        leafY += branchSepScaling 
    else:
      # Assign y on second visit of each internal node
      if not n.isLeaf:
        let
          lo = n.children[0].data.y
          up = n.children[^1].data.y
        n.data.y = (up - lo) / 2 + lo 
  result = copied

let t = parseNewickString("(B:1.0[Test],((E:1.0,F:1.0)D:1.0[Test],G:1.0)C:1.0)A:1.0;", typ=string)
let c = getCoords(t)
echo t.ascii
for i in c.preorder:
  echo i.label, ", ", i.data.x, ", ", i.data.y
echo ""
let c2 = getCoords(t, branchLengthScaling=2.0, branchSepScaling=2.0)
for i in c2.preorder:
  echo i.label, ", ", i.data.x, ", ", i.data.y