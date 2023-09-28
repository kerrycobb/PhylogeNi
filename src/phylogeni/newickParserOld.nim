#TODO: Should rewrite this using a parser library, it has gotten too complex

import ./concepts, ./traverse
import std/[streams, lexbase, strformat, strutils]

type 
  NewickError* = object of IOError

  NewickState = enum
    newickStart, newickTopology, newickLabel, newickLength, newickAnnotation,
    newickEnd, newickEOF
    # TODO: This might be a better way to track state in order to raise errors if
    # a newick string doesn't have any parentheses. Low priority given how 
    # unlikely that is. 
    # newickStart, newickStartLabel, newickStartLength, newickStartTopology, 
    # newickTopology, newickLabel, newickLength, newickEnd, newickEOF
  
  NewickParser[T: TraversableNode] = object of BaseLexer
    root: T 
    currNode: T 
    token: string 
    state: NewickState
    annotationState: bool # False if an annotation has already been parsed 

const newickWhitespace = {' ', '\t', '\c', '\l'}

proc raiseError(p: NewickParser, msg: string) = 
  var 
    lineNum = $p.lineNumber 
    colNum = $p.getColNumber(p.bufpos+1)
    m = fmt"{msg} at line {lineNum}, column {colNum}"
  raise newException(NewickError, m)

proc parseWhitespace(p: var NewickParser, skip=true) = 
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

# # proc parseAnnotation(p: var NewickParser[string], annotation: string) =  
# #   p.currNode.data = annotation

# # proc parseAnnotation(p: var NewickParser[void], annotation: string) = 
# #   discard

proc parseBracket(p: var NewickParser) = 
  # TODO: handle unexpected end of file and newick statement
  mixin parseAnnotation
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
      # p.parseAnnotation(p.token[1..^1])
      p.annotationState = false

proc parseLength[T](p: var NewickParser[T]) =     
  #TODO: Determine if length is float or int for nodetype and convert string appropriately
  var parseLength = true
  while true:
    case p.buf[p.bufpos]
    of '(', ',', ')', ';':
      p.state = newickTopology
      break
    of newickWhitespace: 
      p.parseWhitespace()
    of '[':
      # p.parseBracket()
      p.state = newickAnnotation
      break
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

proc parseLabel(p: var NewickParser) = 
  # TODO: Write when statement to determine if node has label property
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
      p.state = newickAnnotation
      break
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

# proc skipLabel(p: var NewickParser) = 
#   while true:
#     case p.buf[p.bufpos]
#     of 

proc parseData[T](p: var NewickParser[T]) = 
  var annotation = ""
  p.bufpos.inc
  while true:
    case p.buf[p.bufpos] 
    of ']':
      p.state = newickTopology
      p.bufpos.inc()
      break
    else:
      annotation.add(p.buf[p.bufpos])
      p.bufpos.inc()
  # TODO: Call annotation function if Node is annotabale
  when typeof(p.currNode) is ReadableAnnotatedNode:
    p.currNode.parseAnnotation(annotation)

proc parseTopology[T](p: var NewickParser[T]) = 
  # Parse newick tree 
  case p.buf[p.bufpos]
  of '(':
    var newNode = new(T)
    p.currNode.addChild(newNode)
    p.currNode = newNode
    p.bufpos.inc()
    p.state = newickLabel
  of ',':
    var newNode = new(T)
    p.currNode.parent.addChild(newNode)
    p.currNode = newNode
    p.bufpos.inc()
    p.state = newickLabel
  of ')':
    p.currNode = p.currNode.parent
    p.bufpos.inc()
    p.state = newickLabel
  of ';':
    if p.currNode == p.root:
      p.bufpos.inc()
      p.state = newickEnd
    else:
      p.raiseError("Mismatched parentheses") 
  else:
    p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 

proc parseStart(p: var NewickParser) = 
  # Parse beginning of newick file
  while true:
    case p.buf[p.bufpos]
    of '(':
      p.state = newickTopology
      break
    of newickWhitespace:
      p.parseWhitespace()
    of '[':
      p.parseBracket()
      # if p.buf[p.bufpos+1] == '&':
      #   case p.buf[p.bufpos+2]
      #   of 'r', 'R': 
      #     discard
      #   of 'u', 'U':
      #     discard
      #   else:
      #     p.bufpos.inc(2)
      #     p.raiseError(&"Unexpected character \"{p.buf[p.bufpos]}\"") 
      #   if p.buf[p.bufpos+3] == ']':
      #     p.bufpos.inc(4)
      #   else:
      #     p.bufpos.inc(3)
      #     p.raiseError("Expected \"]\"")
      # else:
        # p.parseBracket()
    of EndOfFile:
      # p.state = newickEOF
      # break
      p.raiseError("Unexpected end of file. No newick statment found.")
    else:
      p.state = newickLabel
      break

proc parseNewickStream*(stream: Stream, T: typedesc[TraversableNode]): T =
  ## Parse a newick stream
  var p = NewickParser[T]()
  p.root = new(T)
  p.currNode = p.root
  p.open(stream)
  while true:
    case p.state
    of newickStart:
      p.parseStart()
    of newickTopology:
      p.parseTopology()
    of newickLabel: 
      # when T is LabeledNode:
      p.parseLabel()
      # when not T is LabeledNode:
        # p.skipLabel()
    of newickLength:
      p.parseLength()
    of newickAnnotation:
      p.parseData()
    of newickEnd:
      break
    of newickEOF:
      break
  p.close()
  result = p.root 

proc parseNewickString*(T: typedesc[TraversableNode], str: string): T =
  ## Parse a newick string
  var ss = newStringStream(str)
  result = parseNewickStream(ss, T) 
  ss.close()


  