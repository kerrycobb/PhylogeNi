
proc writeNewickDataString*[T](node: Node[T], str: var string) =
  str.add(node.name)
  str.add(":")
  str.add($node.length)

proc writeNewickString*[T](tree: Tree[T]): string =
  ## Write newick string for Node object
  var str = ""
  for i in tree.newickorder():
    if i.firstVisit == true:
      if i.node.isLeaf():
        i.node.writeNewickDataString(str)
        if i.node != i.node.parent.children[^1]: # not the first node in parents children
          str.add(",")
      else: # is internal node
        str.add("(")
    else: # is second visit to node
      str.add(")")
      i.node.writeNewickDataString(str)
      if (i.node != tree.root) and (i.node != i.node.parent.children[^1]): # is not last node in parents children
        str.add(",")
  str.add(";")
  result = str

proc writeNewickFile*[T](tree: Tree[T], filename:string) =
  # Write a newick file for Node object
  var str = writeNewickString(tree)
  writeFile(filename, str)
