import streams, lexbase, strutils
import ../tree

#TODO: Add error checks

type
  NewickError = object of IOError

  NewickParser = object of BaseLexer
    tree: Tree[void]
    currNode: Node[void]

proc parseNewickStream*(stream: Stream): Tree[void] =
  ## Parse a newick stream
  var
    parser = NewickParser()
    root = Node[void]()
    tree = Tree[void]()
  parser.tree = tree
  parser.tree.root = root
  parser.currNode = root
  parser.open(stream)
  while true:
    case parser.buf[parser.bufpos]
    of EndOfFile:
      raise newException(NewickError, "Unexpected end of newick string at ***")
    of ' ', '\t':
      parser.bufpos.inc()
    of '\c':
      parser.bufpos = lexbase.handleCR(parser, parser.bufpos)
    of '\l': # same as \n
      parser.bufpos = lexbase.handleLF(parser, parser.bufpos)
    of '(':
      var newNode = Node[void]()
      parser.currNode.addChild(newNode)
      parser.currNode = newNode
      parser.bufpos.inc()
    of ')':
      parser.currNode = parser.currNode.parent
      parser.bufpos.inc()
    of ',':
      var newNode = Node[void]()
      parser.currNode.parent.addChild(newNode)
      parser.currNode = newNode
      parser.bufpos.inc()
    of ';':
      parser.bufpos.inc()
      break
    else:
      var
        dataString = ""
      while true:
        case parser.buf[parser.bufpos]
        of ')', ',', ';':
          break
        else:
          dataString.add(parser.buf[parser.bufpos])
          parser.bufpos.inc()
      var split = dataString.split(':')
      parser.currNode.name = split[0]
      if len(split) == 2:
        parser.currNode.length = parseFloat(split[1])
  result = parser.tree

proc parseNewickString*(str: string): Tree[void] =
  ## Parse a newick string
  var ss = newStringStream(str)
  result = parseNewickStream(ss)
  ss.close()

proc parseNewickFile*(path: string): Tree[void] =
  ## Parse a newick file
  var fs = newFileStream(path, fmRead)
  result = parseNewickStream(fs)
  fs.close()

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
