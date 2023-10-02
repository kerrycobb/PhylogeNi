import tables
export tables # TODO: How to avoid needing this
import strformat
import npeg
import ./concepts

type
  DataNode*[T] = ref object
    parent*: DataNode[T]
    children*: seq[DataNode[T]]
    label*: string
    length*: float
    data*: T 
  

proc addChild*[T](parent, child: DataNode[T]) = 
  ## A bug in Nim currently requires that each type matching  
  ## a TraversableNode must have an addChild proc written for it. 
  ## https://github.com/nim-lang/Nim/issues/22723
  parent.children.add(child)
  child.parent = parent


# Void Data
proc parseNewickData*[T](n: DataNode[void], data: string) = 
  discard

proc writeNewickData*[T](n: DataNode[void]): string = 
  result = ""

# String Data
proc parseNewickData*[T](n: DataNode[string], data: string) = 
  n.data = data 

proc writeNewickData*[T](n: DataNode[string]): string = 
  n.data

# NHX Data
type 
  NHXData* = OrderedTable[string, string]

# TODO: Make object variant to use as value for table and modify parser to 
# recognize and assign

proc parseNewickData*(n: DataNode[NHXData], data: string) = 
  var node = n
  let p = peg "parser":
    val     <- *(Print - {'[', ']'})
    key     <- *(Alnum | '_')
    pair    <- ':' * >key * '=' * >val: 
      node.data[$1] = $2 
    pairs   <- ?(pair * *(',' * pair)) 
    parser  <- "[&&NHX" * pairs * ']'
  let r = p.match(data)
  assert r.ok

proc writeNewickData*(n: DataNode[NHXData]): string = 
  result.add("[&&NHX")
  for k, v in n.data.pairs:
    result.add(fmt":{k}={v}")
  result.add(']')