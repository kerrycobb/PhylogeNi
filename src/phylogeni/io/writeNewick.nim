import ../tree, strformat

proc writeAnnotation(node: Node[string], str: var string) = 
  str.add(fmt"[&{node.data}]")

proc writeAnnotation(node: Node[void], str: var string) = 
  discard

proc writeNewickData[T](node: Node[T], str: var string) =
  str.add(node.label)
  str.add(fmt":{$node.length}")
  node.writeAnnotation(str)

proc writeNewickString*[T](tree: Tree[T]): string =
  mixin writeNewickData
  ## Write newick string for Node object
  var str = ""
  if tree.rooted:
    str.add("[&R]")
  else:
    str.add("[&U]")
  for i in tree.newickorder():
    if i.firstVisit == true:
      if i.node.isLeaf():
        i.node.writeNewickData(str)
        if i.node != i.node.parent.children[^1]: # not the first node in parents children
          str.add(",")
      else: # is internal node
        str.add("(")
    else: # is second visit to node
      str.add(")")
      i.node.writeNewickData(str)
      if (i.node != tree.root) and (i.node != i.node.parent.children[^1]): # is not last node in parents children
        str.add(",")
  str.add(";")
  result = str

proc writeNewickFile*[T](tree: Tree[T], filename:string) =
  # Write a newick file for Node object
  var str = writeNewickString(tree)
  writeFile(filename, str)
