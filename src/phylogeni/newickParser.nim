import npeg
import ./concepts
import ./nodeTypes
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
  # Workaround for bug in Nim
  # https://github.com/zevv/npeg/issues/68
  # https://github.com/nim-lang/Nim/issues/22740
  template `>`(a: untyped): untyped = discard
  template `*`(a: untyped): untyped = discard
  template `-`(a: untyped): untyped = discard
  template `+`(a: untyped): untyped = discard

proc parseNewickString*(str: string, T: typedesc[TraversableNode] = DataNode[void]): T = 
  # TODO: Better error messages
  # - empty string
  # - missing ';'
  # - int/float parsing
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
        # parseLabel(curr, $1) # Can't use $ operator right now due to bug https://github.com/zevv/npeg/issues/68
        parseLabel(curr, capture[1].s)
    length     <- ':' * >?(+Digit * ?('.' * +Digit)): 
    #     parseLength(curr, $1) # Can't use $ operator right now due to bug https://github.com/zevv/npeg/issues/68
        parseLength(curr, capture[1].s)
    data       <- >comment: 
        # parseData(curr, $1) # Can't use $ operator right now due to bug https://github.com/zevv/npeg/issues/68
        parseData(curr, capture[1].s)
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

proc parseNewickFile*(path: string, T: typedesc[TraversableNode] = DataNode[void]): T = 
  var str = readFile(path)
  result = parseNewickString(T, str)

proc genericBugWorkaround() = 
  # Needed to work around bug in Nim 
  # https://github.com/zevv/npeg/issues/68
  # https://github.com/nim-lang/Nim/issues/22740
  discard parseNewickString(";", DataNode[void])
