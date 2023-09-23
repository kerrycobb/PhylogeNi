
# TODO: Remove this once generics are fixed
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

proc parseNewickData*(n: Nd, data: string) = 
  n.data = data 



################################################################################
# New parser
#TODO: Make parser accept generics once bug is fixed
# https://github.com/zevv/npeg/issues/68
# https://github.com/nim-lang/Nim/issues/22740


import npeg
import ./concepts
import std/[strutils, strformat] 

type
  NewickError* = object of IOError

# proc newChildNode[T](curr: var T) = 
proc newChildNode(curr: var Nd) = 
  var newNode = Nd()
  curr.addChild(newNode)
  curr = newNode

# proc newSisterNode[T](curr: var T) = 
proc newSisterNode(curr: var Nd) = 
  var newNode = Nd()
  curr.parent.addChild(newNode)
  curr = newNode

# proc branchTerminated[T](curr: var T) = 
proc branchTerminated(curr: var Nd) = 
  curr = curr.parent

# proc parseLabel[T](curr: var T, label: string) = 
proc parseLabel(curr: var Nd, label: string) = 
  when curr is LabeledNode:
    curr.label = label 

# proc parseLength[T](curr: var T, length: string) = 
proc parseLength(curr: var Nd, length: string) = 
  # TODO: Handle errors parsing int and float
  when curr is LengthNode:
    if length.len > 0:
      when curr.length is int:
        curr.length = parseInt(length)
      when curr.length is float:
        curr.length = parseFloat(length)

# proc parseData[T](curr: var T, data: string) =
proc parseData(curr: var Nd, data: string) =
  when curr.is ReadableDataNode:
    # mixin parseNewickData
    parseNewickData(curr, data)

# proc parseNewickString*(T: typedesc[TraversableNode], str:string): T = 
proc parseNewickString*(str:string): Nd = 
  var
    # root = new(T)
    root = new(Nd)
    curr = root
    dataState = true 
  let p = peg "newick":
    # TODO: How to move this elsewhere or even simplify?:
    dataChars <- Print - {'[', ']'} 
    S           <- *Space
    comment     <- ?('[' * >*dataChars * ']')
    # TODO: Why doesn't this work?
    # nestComment <- >('[' * *(dataChars | nestComment ) * ']') 
    # comment     <- ?('[' * >*(dataChars | nested) * ']')
    stop        <- ';' 
    lBrack      <- '(' : 
                   newChildNode(curr)
    rBrack      <- ')' : 
                   branchTerminated(curr)
    comma       <- ',' : 
                   newSisterNode(curr) 
    label       <- >+(Alnum | '_'): 
                   parseLabel(curr, $1)
    length      <- ':' * >?(+Digit * ?('.' * +Digit)): 
                   parseLength(curr, $1)
    data        <- '[' * >*dataChars * ']': 
                   parseData(curr, $1)
    annotation  <- ?data * S * ?label * S * ?data * S * ?length * S * ?data: 
                   dataState=true 
    leaf        <- annotation  
    branchset   <- (internal | leaf) * S * *(comma * S * (internal | leaf))  
    internal    <- S * lBrack * S * ?branchset * S * rBrack * S * annotation
    newick      <- S * comment * (internal | leaf) * S * stop * S * !1 

  let r = p.match(str)
  echo r
  if not r.ok:
    var msg = &"Unexpected '{str[r.matchMax]}' at position {r.matchMax} of Newick string. Problem may originate before this position."
    raise newException(NewickError, msg)
  if curr != root:
    var msg = "Invalid Newick string."
    raise newException(NewickError, msg)
  result = root

# proc parseNewickFile*(T: typedesc[TraversableNode], path: string): T = 
proc parseNewickFile*(path: string): Nd = 
  var str = readFile(path)
  result = parseNewickString(str)



# ###################################################
# # Testing

# var 
#   str = "(A:1.0[Test],B,(C,D));"
#   t = parseNewickString(str)
# echo t.ascii

# # import ./traverse
# # for i in t.preorder:
# #   echo i[]

# discard parseNewickString("(,,(,));")
# discard parseNewickString("(A,B,(C,D));")
# discard parseNewickString("(A,B,(C,D)E)F;")
# discard parseNewickString("(:0.1,:0.2,(:0.3,:0.4):0.5);")
# discard parseNewickString("(:0.1,:0.2,(:0.3,:0.4):0.5):0.0;")
# discard parseNewickString("(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);")
# discard parseNewickString("(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;")
# discard parseNewickString("((B:0.2,(C:0.3,D:0.4)E:0.5)F:0.1)A;")
# # # TODO: Make test cases with data annotation
# # # TODO: Make test cases expected to fail