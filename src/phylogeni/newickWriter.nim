import ./concepts, ./traverse

func writeAnnotations(node: TraversableNode, str: var string, data: bool) =
  when typeof(node) is LabeledNode:
    str.add(node.label)
  when typeof(node) is LengthNode: 
    str.add(':')
    str.add($node.length)
  when typeof(node) is WritableDataNode:
    mixin writeNewickData 
    if data:
      str.add(node.writeNewickData)

proc writeNewickString*(root: TraversableNode, data=true): string =
  ## Write newick string for Node object
  var str = ""
  for i in root.allorder():
    case i.direction
    of ascendingTree:
      if i.node.isLeaf():
        i.node.writeAnnotations(str, data)
        if i.node != i.node.parent.children[^1]: # not the first node in parents children
          str.add(",")
      else: # internal node
        str.add("(")
    of descendingTree:
      str.add(")")
      i.node.writeAnnotations(str, data)
      if (i.node != root) and (i.node != i.node.parent.children[^1]): # not last node in parents children
        str.add(",")
  str.add(";")
  result = str