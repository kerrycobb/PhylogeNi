import npeg
import ./concepts
import std/[strutils, strformat] 

type
  NewickError* = object of IOError

proc newChildNode[T](curr: var T) = 
  mixin addChild
  var newNode = new(T)
  curr.addChild(newNode)
  curr = newNode

proc newSisterNode[T](curr: var T) = 
  mixin addChild
  var newNode = new(T)
  curr.parent.addChild(newNode)
  curr = newNode

proc branchTerminated[T](curr: var T) = 
  curr = curr.parent

proc parseLabel[T](curr: var T, label: string) = 
  when curr is LabeledNode:
    curr.label = label 

proc parseLength[T](curr: T, length: string) = 
  # TODO: Handle errors parsing int and float
  when curr is LengthNode:
    if length.len > 0:
      when curr.length is int:
        curr.length = parseInt(length)
      when curr.length is float:
        curr.length = parseFloat(length)

proc parseData[T](curr: var T, data: string) =
  when curr is ReadableDataNode:
    mixin parseNewickData
    parseNewickData(curr, data)

template genericBugWorkAround() =
  # Template definitions as workaround for bug in Nim
  # https://github.com/zevv/npeg/issues/68
  # https://github.com/nim-lang/Nim/issues/22740
  template `>`(a: untyped): untyped = discard
  template `*`(a: untyped): untyped = discard
  template `-`(a: untyped): untyped = discard
  template `+`(a: untyped): untyped = discard
  # template `?`(a: untyped): untyped = discard
  # template `!`(a: untyped): untyped = discard
  template `$`(a: untyped): untyped = discard
  
proc parseNewickString*(T: typedesc[TraversableNode], str:string): T = 
  genericBugWorkAround()
  var
    root = new(T)
    curr = root
  let p = peg "newick":
    dataChars  <- Print - {'[', ']'} 
    S          <- *Space
    nComment   <- >('[' * *(nComment | dataChars) * ']')
    comment    <- '[' * >*(nComment | dataChars) * ']'
    stop       <- ';' 
    lBrack     <- '(': 
        newChildNode(curr)
    rBrack     <- ')': 
        branchTerminated(curr)
    comma      <- ',': 
        newSisterNode(curr) 
    label      <- >+(Alnum | '_'): 
        parseLabel(curr, $1)
    length     <- ':' * >?(+Digit * ?('.' * +Digit)): 
        parseLength(curr, $1)
    data       <- >comment: 
        parseData(curr, $1)
    annotation <- ?data * S * ?label * S * ?data * S * ?length * S * ?data  
    leaf       <- annotation  
    branchset  <- (internal | leaf) * S * *(comma * S * (internal | leaf))  
    internal   <- S * lBrack * S * ?branchset * S * rBrack * S * annotation
    start      <- *( Space | comment )
    newick     <- start * (internal | leaf) * S * stop * S * !1 

  let r = p.match(str)
  if not r.ok:
    var msg = &"Unexpected '{str[r.matchMax]}' at position {r.matchMax} of Newick string. Problem may originate before this position."
    raise newException(NewickError, msg)
  if curr != root:
    var msg = "Invalid Newick string."
    raise newException(NewickError, msg)
  result = root

proc parseNewickFile*(T: typedesc[TraversableNode], path: string): T = 
  var str = readFile(path)
  result = parseNewickString(T, str)


# ###################################################
# # Testing

type
  Nd* = ref object
    parent*: Nd
    children*: seq[Nd]
    label*: string
    length*: float
    data*: string

proc addChild*(parent, child: Nd) = 
  ## A bug in Nim currently requires that each type matching that is 
  ## a TraversableNode must have an addChild proc written for it. 
  ## This will no longer be necesary when the bug is fixed
  ## https://github.com/nim-lang/Nim/issues/22723
  # TODO: Make this a concept once that works 
  parent.children.add(child)
  child.parent = parent

proc parseNewickData*(n: Nd, data: string) = 
  n.data = data 

proc writeNewickData*(n: Nd): string = 
  n.data

# This works
var t = parseNewickString(Nd, "[[Test]]((([Test]f:1.0[Test[Test]],g:1.0[Test])e:1.0[Test],d:1.0[Test])c:1.0[Test],b:1.0[Test])a:1.0[Test];")
echo t.ascii