import streams, lexbase, strutils
import ../tree

#TODO: Add error checks
#TODO: Maybe use a more intuitive parameter name than dataType
# and could also make a base dataType object that each would inherit from
#TODO:" Allow for quoted node labels that permit blank spaces

type
  NewickError = object of IOError

  NewickParser[T] = object of BaseLexer
    tree: Tree[T]
    currNode: Node[T]

proc parseNewickData(parser: var NewickParser[string]) = 
  #TODO: Make this work
  var
    dataString = ""
  while true:
    case parser.buf[parser.bufpos]
    of ')', ',', ';':
      parser.currNode.data = dataString
      break
    else:
      dataString.add(parser.buf[parser.bufpos])
      parser.bufpos.inc()
  var split = dataString.split(':')
  parser.currNode.name = split[0]
  if len(split) == 2:
    parser.currNode.length = parseFloat(split[1])

proc parseNewickData(parser: var NewickParser[void]) = 
  var
    dataString = ""
  while true:
    case parser.buf[parser.bufpos]
    of ')', ',', ';':
      echo dataString
      break
    else:
      dataString.add(parser.buf[parser.bufpos])
      parser.bufpos.inc()
  var split = dataString.split(':')
  parser.currNode.name = split[0]
  if len(split) == 2:
    parser.currNode.length = parseFloat(split[1])

proc parseNewickStream*(stream: Stream, dataType=void): Tree[dataType] =
  ## Parse a newick stream
  var
    parser = NewickParser[dataType]()
  parser.tree = Tree[dataType]()
  parser.tree.root = Node[dataType]()
  parser.currNode = parser.tree.root
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
      var newNode = Node[dataType]()
      parser.currNode.addChild(newNode)
      parser.currNode = newNode
      parser.bufpos.inc()
    of ')':
      parser.currNode = parser.currNode.parent
      parser.bufpos.inc()
    of ',':
      var newNode = Node[dataType]()
      parser.currNode.parent.addChild(newNode)
      parser.currNode = newNode
      parser.bufpos.inc()
    of ';':
      parser.bufpos.inc()
      break
    else:
      # parser.parseNewickData()
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

proc parseNewickString*(str: string, dataType=void): Tree[dataType] =
  ## Parse a newick string
  var ss = newStringStream(str)
  result = parseNewickStream(ss, dataType)
  ss.close()

proc parseNewickFile*(path: string, dataType=void): Tree[dataType] =
  ## Parse a newick file
  var fs = newFileStream(path, fmRead)
  result = parseNewickStream(fs, dataType)
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


let 
  ts = "((C:1.0,D:1.0)B:1.0,(F:1.0,G:1.0)E:1.0)A:1.0;"
  t = parseNewickString(ts, dataType=string)

for i in t.preorder():
  echo i[]