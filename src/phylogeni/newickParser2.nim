
type
  Nd* = ref object
    parent*: Nd
    children*: seq[Nd]
    label*: string
    length*: float
    data*: string

proc addChild*(parent, child: Nd) = 
  parent.children.add(child)
  child.parent = parent

proc readNewickAnnotation*(n: Nd, data: string) = 
  n.data = data 

################################################################################
# New parser

import npeg
import ./concepts
import std/strutils, strformat

type
  NewickError* = object of IOError

proc newChildNode(curr: var Nd) = 
  var newNode = Nd()
  curr.addChild(newNode)
  curr = newNode

proc newSisterNode(curr: var Nd) = 
  var newNode = Nd()
  curr.parent.addChild(newNode)
  curr = newNode

proc branchTerminated(curr: var Nd) = 
  curr = curr.parent

proc parseLabel(curr: var Nd, label: string) = 
  when curr is LabeledNode:
    curr.label = label 

proc parseLength(curr: var Nd, length: string) = 
  # TODO: Handle errors parsing int and float
  when curr is LengthNode:
    if length.len > 0:
      when curr.length is int:
        curr.length = parseInt(length)
      when curr.length is float:
        curr.length = parseFloat(length)

proc parseData(curr: var Nd, data: string) =
  when curr.is ReadableAnnotatedNode:
    curr.parseNewickData(curr, data)

proc parseNewickString(str:string): Nd = 
  var
    root = new(Nd)
    curr = root
  let p = peg "newick":
    # TODO: How to move this elsewhere or even simplify?:
    NewickDataSymbols <- {' ', '!', '\"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '\\', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~'}
    S           <- *Space 
    comment     <- ?(S * '[' * >*NewickDataSymbols * ']')
    stop        <- S * ';' 
    lBrack      <- S * '(' * S:
      newChildNode(curr)
    rBrack      <- S * ')' * S:
      branchTerminated(curr)
    comma       <- S * ',' * S:
      newSisterNode(curr) 
    label       <- >+(Alpha | '_'):
      parseLabel(curr, $1)
    length      <- ':' * S * >?(+Digit * ?('.' * +Digit)):
      parseLength(curr, $1)
    data        <- '[' * >*NewickDataSymbols * ']':
      parseData(curr, $1)
    annotation  <- ?label * S * ?length * S * ?data 
    leaf        <- annotation  
    branchset   <- (internal | leaf) * *(comma * (internal | leaf))  
    internal    <- lBrack * ?branchset * rBrack * annotation
    newick      <- comment * (internal | leaf) * stop * S * !1 

  let r = p.match(str)
  if not r.ok:
    var msg: string
    if curr != root:
      msg = "Invalid Newick string. May have unequal '(' and ')'"
    else:
      msg = &"Unexpected '{str[r.matchMax]}' at position {r.matchMax} of Newick string. Problem may originate before this position."
    raise newException(NewickError, msg)
  result = root

proc parseNewickFile(path: string): Nd = 
  var str = readFile(path)
  result = parseNewickString(str)

###################################################
# Testing

var 
  str = "(A,B:,(C,D));"
  t = parseNewickString(str)
echo t.ascii

# import ./traverse
# for i in t.preorder:
  # echo i[]

# discard parseNewickString("(,,(,));")
# discard parseNewickString("(A,B,(C,D));")
# discard parseNewickString("(A,B,(C,D)E)F;")
# discard parseNewickString("(:0.1,:0.2,(:0.3,:0.4):0.5);")
# discard parseNewickString("(:0.1,:0.2,(:0.3,:0.4):0.5):0.0;")
# discard parseNewickString("(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);")
# discard parseNewickString("(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;")
# discard parseNewickString("((B:0.2,(C:0.3,D:0.4)E:0.5)F:0.1)A;")
# # TODO: Make test cases with data annotation
# # TODO: Make test cases expected to fail