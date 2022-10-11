import ./phylogeni/[
  tree,
  io/parseNewick,
  io/writeNewick,
  simulate]

export tree,
       parseNewick,
       writeNewick,
       simulate

## =========
## PhylogeNi
## =========
## 
## The types are `Tree` and `Node`
## PhylogeNi has a number of functions for working with Trees and Nodes
runnableExamples:
  var t = treeFromString("(B:1.0,C:1.0)A:1.0;")
  for i in t.preorder():
    if i.label == "C":
      i.addChild(newNode("D", 1.0))
      i.addChild(newNode("E", 1.0))
  echo t 

  # -A /-B
  #    \C /-D
  #       \-E
  
  t.ladderize(Descending)
  var str = t.writeNewickString()
  echo str

  # [&U]((D:1.0,E:1.0)C:1.0,B:1.0)A:1.0;

##
## `Node` is a generic type. The data field of a `Node` can be any object.  
## 
## One great feature of PhylogeNi is that you do not need to write your  
## own parser for a custom type if you are storing or reading these data in a newick file

runnableExamples:
  import std/strutils
  import std/strformat
  
  type 
    CustomData = object
      posterior: float
      credibleInterval: tuple[lower, upper: float]
  
  let treeStr = "(B:1.0[&p:0.95,ci:0.9-1.0],C:1.0[&p:0.95,ci:0.9-1.0])A:1.0[&p:0.95,ci:0.9-1.0];"
  
  proc parseAnnotation(p: var NewickParser[CustomData], annotation: string) = 
    let annotations = annotation.split(",") 
    var 
      data = CustomData()
      dataCheck = (p: false, ci: false)
    for i in annotations:
      let split = i.split(":")
      assert split.len == 2
      case split[0]
      of "p":
        data.posterior = parseFloat(split[1])
        dataCheck.p = true
      of "ci":
        let ci = split[1].split("-")
        assert ci.len == 2
        data.credibleInterval = (parseFloat(ci[0]), parseFloat(ci[1]))
        dataCheck.ci = true
      else:
        raise newException(NewickError, "Invalid Annotation")
    if not dataCheck.p or not dataCheck.ci: 
      raise newException(NewickError, "")
    p.currNode.data = data
    echo data
  
  proc writeAnnotation(node: Node[CustomData], str: var string) = 
    str.add(fmt"[p:{$node.data.posterior},ci:{$node.data.credibleInterval.lower}-{$node.data.credibleInterval.upper}]")
  
  let 
    t = treeFromString(treeStr, CustomData) 
    str = t.writeNewickString()
  echo str
  # [&U](B:1.0[p:0.95,ci:0.9-1.0],C:1.0[p:0.95,ci:0.9-1.0])A:1.0[p:0.95,ci:0.9-1.0];
