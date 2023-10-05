import tables
export tables # TODO: How to avoid needing this
import strformat
import npeg
import ./concepts

type
  NodeDataKind* = enum ndString, ndFloat, ndInt, ndArray 

  NodeData* = object
    case kind*: NodeDataKind
    of ndString:
      ndString*: string
    of ndFloat:
      ndFloat*: float
    of ndInt:
      ndInt*: int
    of ndArray:
      ndArray*: seq[NodeData]
  
proc `$`*(d: NodeData): string =
  case d.kind
  of ndString:
    result = d.ndString 
  of ndFloat:
    result = $d.ndFloat 
  of ndInt:
    result = $d.ndInt
  of ndArray:
    result.add('{')
    for i, x in d.ndArray:
      result.add($x)
      if i < d.ndArray.len - 1:
        result.add(',')
    result.add('}')

# Generic data node
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
type
  NHNode* = DataNode[void]

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
# TODO: Look into implementing this using distinct table with borrowed procs 
# instead of makeing a whole new Node type
type
  NHXNode* = ref object
    parent*: NHXNode
    children*: seq[NHXNode]
    label*: string
    length*: float
    data*: OrderedTable[string, NodeData] 

proc addChild*(parent, child: NHXNode) = 
  ## A bug in Nim currently requires that each type matching  
  ## a TraversableNode must have an addChild proc written for it. 
  ## https://github.com/nim-lang/Nim/issues/22723
  parent.children.add(child)
  child.parent = parent

proc parseNewickData*(n: NHXNode, data: string) = 
  # TODO: Parse things other than strings into their NodeData variant 
  var node = n
  let p = peg "parser":
    val     <- *(Print - {'[', ']'})
    key     <- *(Alnum | '_')
    pair    <- ':' * >key * '=' * >val: 
      node.data[capture[1].s] = NodeData(kind: ndString, ndString:capture[2].s) 
    pairs   <- ?(pair * *(',' * pair)) 
    parser  <- "[&&NHX" * pairs * ']'
  let r = p.match(data)
  assert r.ok

proc writeNewickData*(n: NHXNode): string = 
  result.add("[&&NHX")
  for k, v in n.data.pairs:
    result.add(fmt":{k}={$v}")
  result.add(']')


# Nexus Data
# TODO: Look into implementing this using distinct table with borrowed procs 
# instead of makeing a whole new Node type
type
  NexusNode* = ref object
    parent*: NexusNode
    children*: seq[NexusNode]
    label*: string
    length*: float
    data*: OrderedTable[string, NodeData] 

proc addChild*(parent, child: NexusNode) = 
  ## A bug in Nim currently requires that each type matching  
  ## a TraversableNode must have an addChild proc written for it. 
  ## https://github.com/nim-lang/Nim/issues/22723
  parent.children.add(child)
  child.parent = parent

proc parseNewickData*(n: NexusNode, data: string) = 
# proc parseNewickData*(data: string) = 
  # TODO: Parse things other than strings into their NodeData variant 
  # echo data
  var node = n
  let p = peg "parser":
    value     <- *(Alnum | '.')
    darray  <- '{' * *(Alnum | {'.', ','}) * '}'
    key     <- *(Alnum | {'_', '%', '-', '.'})
    pair    <- >key * '=' * >(darray | value):
      node.data[capture[1].s] = NodeData(kind: ndString, ndString:capture[2].s) 
    pairs   <- ?pair * *(',' * pair)
    parser  <- "[&" * pairs  * @']'
  let r = p.match(data)
  assert r.ok

proc writeNewickData*(n: NexusNode): string = 
  result.add("[&")
  for k, v in n.data.pairs:
    result.add(fmt",{k}={$v}")
  result.add(']')

# var str = "[&height_95%_HPD={350.7986790000001,350.99962300000016},length=0.0,posterior=1.0,height_median=350.96059650000007,height_range={350.73167,350.99962300000016},height=350.9389471000002]"
# parseNewickData(str)
