import ../tree
import std/strformat

func writeNewickData(node: Node[string], str: var string) = 
  str.add(fmt"[&{node.data}]")

func writeNewickData(node: Node[void], str: var string) = 
  discard

func writeNewickData[T](node: Node[T], str: var string) =
  mixin writeAnnotation 
  str.add(node.label)
  str.add(fmt":{$node.length}")
  node.writeAnnotation(str)

func writeNewickString*[T](tree: Node[T]): string =
  ## Write newick string for Node object
  var str = ""
  for i in tree.newickorder():
    if i.firstVisit == true:
      if i.node.isLeaf():
        str.add(i.node.writeNewickData)
        if i.node != i.node.parent.children[^1]: # not the first node in parents children
          str.add(",")
      else: # is internal node
        str.add("(")
    else: # is second visit to node
      str.add(")")
      str.add(i.node.writeNewickData)
      if (i.node != tree) and (i.node != i.node.parent.children[^1]): # is not last node in parents children
        str.add(",")
  str.add(";")
  result = str

proc writeNewickFile*[T](tree: Node[T], filename:string) =
  # Write a newick file for Node object
  var str = writeNewickString(tree)
  writeFile(filename, str)
