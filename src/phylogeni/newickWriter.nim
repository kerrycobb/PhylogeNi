import ./concepts, ./traverse

func writeNewickData(node: TraversableNode, str: var string, annotation: bool) =
  when typeof(node) is LabeledNode:
    str.add(node.label)
  when typeof(node) is LengthNode: 
    str.add(':')
    str.add($node.length)
  when typeof(node) is WritableAnnotatedNode:
    if annotation:
      str.add(node.writeAnnotation)

func writeNewickString*(root: TraversableNode, annotation=true): string =
  ## Write newick string for Node object
  var str = ""
  for i in root.newickorder():
    if i.state == ascendingTree:
      if i.node.isLeaf():
        i.node.writeNewickData(str, annotation)
        if i.node != i.parent.children[^1]: # not the first node in parents children
          str.add(",")
      else: # internal node
        str.add("(")
    else: # descending tree 
      str.add(")")
      i.node.writeNewickData(str, annotation)
      if (i.node != root) and (i.node != i.parent.children[^1]): # not last node in parents children
        str.add(",")
  str.add(";")
  result = str