import streams, lexbase, strformat, strutils 
import ../tree

type 
  NewickError* = object of IOError

  NewickState = enum
    newickStart, newickTopology, newickLabel, newickLength, newickEnd, newickEOF
  
  NewickParser[T] = object of BaseLexer
    tree: Tree[T]
    currNode: Node[T]
    token : string 
    state: NewickState
    annotationState: bool # False if an annotation has already been parsed 

const newickWhitespace = {' ', '\t', '\c', '\l'}

proc raiseError[T](p: NewickParser[T], msg: string) = 
  var 
    lineNum = $p.lineNumber 
    colNum = $p.getColNumber(p.bufpos+1)
    m = fmt"{msg} at line {lineNum}, column {colNum}"
  raise newException(NewickError, m)

proc parseWhitespace[T](p: var NewickParser[T], skip=true) = 
  while true:
    case p.buf[p.bufpos]
    of ' ', '\t':
      if not skip: p.token.add(p.buf[p.bufpos])
      p.bufpos.inc()
    of '\c':
      if not skip: p.token.add(p.buf[p.bufpos])
      p.bufpos = lexbase.handleCR(p, p.bufpos)
    of '\l': # same as \n
      if not skip: p.token.add(p.buf[p.bufpos])
      p.bufpos = lexbase.handleLF(p, p.bufpos)
    else:
      break

proc parseAnnotation(p: var NewickParser[string], annotation: string) =  
  p.currNode.data = annotation 

proc parseAnnotation(p: var NewickParser[void], annotation: string) = 
  discard

proc parseComment[T](p: var NewickParser[T], showComments=false) = 
  p.token = ""
  p.bufpos.inc()
  while true:
    case p.buf[p.bufpos]
    of ']':
      p.bufpos.inc()
      break
    of newickWhitespace:
      p.parseWhitespace(skip=false)
    else:
      p.token.add(p.buf[p.bufpos])
      p.bufpos.inc()
  if p.token.startswith('&'):
    if p.annotationState:
      p.parseAnnotation(p.token)
      p.annotationState = false
  else:
    if showComments:
      echo p.token 

proc parseLength[T](p: var NewickParser[T]) =     
  var parseLength = true
  while true:
    case p.buf[p.bufpos]
    of '(', ',', ')', ';':
      p.state = newickTopology
      break
    of newickWhitespace: 
      p.parseWhitespace()
    of '[':
      p.parseComment()
    of EndOfFile:
      p.raiseError("Unexpected end of stream")
    else:
      if parseLength:
        p.token = ""
        while true:
          case p.buf[p.bufpos]
          of '(', ',', ')', ';', '[', newickWhitespace, EndOfFile:
            parseLength = false
            break
          of '"':
            p.raiseError("Unexpected \"") 
          else:
            p.token.add(p.buf[p.bufpos])
            p.bufpos.inc()
        p.currNode.length = parseFloat(p.token)
        parseLength = false

proc parseLabel[T](p: var NewickParser[T]) = 
  var parseLabel = true
  p.annotationState = true
  while true:
    case p.buf[p.bufpos]
    of '(', ',', ')', ';':
      p.state = newickTopology
      break
    of ':':
      p.state = newickLength
      p.bufpos.inc()
      break
    of '[':
      p.parseComment()
    of newickWhitespace:
      p.parseWhitespace()
    of EndOfFile:
      p.raiseError("Unexpected end of stream")
    of '"':
      # Parse quoted text
      if parseLabel:        
        p.token = ""
        p.bufpos.inc()
        while true:
          case p.buf[p.bufpos]
          of '"': 
            p.bufpos.inc()
            break
          of newickWhitespace: 
            p.parseWhitespace(skip=false)
          else:
            p.token.add(p.buf[p.bufpos])
            p.bufpos.inc()
        p.currNode.label = p.token
        parseLabel = false
      else: 
        p.raiseError("Unexpected \"")
    else:
      # Parse unquoted text
      if parseLabel:
        p.token = ""
        while true:
          case p.buf[p.bufpos]
          of '(', ',', ')', ';', ':', '[', ']', newickWhitespace, EndOfFile:
            parseLabel = false
            break
          of '"':
            p.raiseError("Unexpected \"") 
          else:
            p.token.add(p.buf[p.bufpos])
            p.bufpos.inc()
        p.currNode.label = p.token
        parseLabel = false
      else:
        p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 

proc parseTopology[T](p: var NewickParser[T]) = 
  # Parse newick tree 
  case p.buf[p.bufpos]
  of '(':
    var newNode = Node[T]()
    p.currNode.addChild(newNode)
    p.currNode = newNode
    p.bufpos.inc()
    p.state = newickLabel
  of ',':
    var newNode = Node[T]()
    p.currNode.parent.addChild(newNode)
    p.currNode = newNode
    p.bufpos.inc()
    p.state = newickLabel
  of ')':
    p.currNode = p.currNode.parent
    p.bufpos.inc()
    p.state = newickLabel
  of ';':
    if p.currNode == p.tree.root:
      p.bufpos.inc()
      p.state = newickEnd
    else:
      p.raiseError("Mismatched parentheses") 
  else:
    p.raiseError(&"Internal error, report possible bug") 

proc parseStart[T](p: var NewickParser[T]) = 
  # Parse beginning of newick file
  while true:
    case p.buf[p.bufpos]
    of '(':
      p.state = newickTopology
      break
    of newickWhitespace:
      p.parseWhitespace()
    of '[':
      if p.buf[p.bufpos+1] == '&':
        case p.buf[p.bufpos+2]
        of 'r', 'R': 
          p.tree.rooted = true
        of 'u', 'U':
          p.tree.rooted = false
        else:
          p.bufpos.inc(2)
          p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 
        if p.buf[p.bufpos+3] == ']':
          p.bufpos.inc(4)
        else:
          p.bufpos.inc(3)
          p.raiseError("Expected \"]\"")
      else:
        p.parseComment()
    of EndOfFile:
      p.state = newickEOF
      break
    else:
      p.state = newickLabel
      break

proc parseTree[T](p: var NewickParser[T]) = 
  p.parseWhitespace()
  while true:
    case p.state
    of newickStart:
      p.parseStart()
    of newickTopology:
      p.parseTopology()
    of newickLabel: 
      p.parseLabel()
    of newickLength:
      p.parseLength()
    of newickEnd:
      break
    of newickEOF:
      break

proc parseNewickStream*[T](tree: var Tree[T], stream: Stream) =
  ## Parse a newick stream
  var
    p = NewickParser[T]()
  p.tree = tree 
  p.tree.root = Node[T]()
  p.currNode = p.tree.root
  p.open(stream)
  p.parseTree()
  p.close()

proc parseNewickStream*[T](treeSeq: var TreeSeq[T], stream: Stream) =
  ## Parse a newick stream
  var
    p = NewickParser[T]()
  p.open(stream)
  while true:
    p.state = newickStart
    p.tree = Tree[T]() 
    p.tree.root = Node[T]()
    p.currNode = p.tree.root
    p.parseTree()
    case p.state
    of newickEOF:
      break
    of newickEnd:
      treeSeq.add(p.tree)
    else:
      p.raiseError("Internal error, report possible bug") 
  p.close()

proc parseNewickString*[T](tree: var Tree[T], str: string) =
  ## Parse a newick string
  var ss = newStringStream(str)
  tree.parseNewickStream(ss)
  ss.close()

proc parseNewickString*[T](treesSeq: var TreeSeq[T], str: string) =
  ## Parse a newick string
  var ss = newStringStream(str)
  treesSeq.parseNewickStream(ss)
  ss.close()

proc parseNewickFile*[T](tree: var Tree[T], path: string) =
  ## Parse a newick file
  var fs = newFileStream(path, fmRead)
  tree.parseNewickStream(fs)
  fs.close()

proc parseNewickFile*[T](treeSeq: var TreeSeq[T], path: string) =
  ## Parse a newick file
  var fs = newFileStream(path, fmRead)
  treeSeq.parseNewickStream(fs)
  fs.close()



