import ./phylogeni/[
  tree,
  io/parseNewick,
  io/writeNewick,
  simulate
  ]

export tree,
       parseNewick,
       writeNewick,
       simulate

## =========
## PhylogeNi
## =========
## 
## PhylogeNi is a Nim library for working with phylogenetic trees.
##  
 
runnableExamples:
  var t = treeFromString("(B:1.0,C:1.0)A:1.0;")

  echo t

  # -A /-B
  #    \-C

  for i in t.preorder():
    if i.label == "C":
      i.addChild(newNode("D", 1.0))
      i.addChild(newNode("E", 1.0))
  t.ladderize(Ascending)
  echo t

  #    /C /-D
  # -A|   \-E
  #    \-B

  var str = t.writeNewickString()
  echo str
  # [&U]((D:1.0,E:1.0)C:1.0,B:1.0)A:1.0;

## 
## See the module docs for more details: 
## `tree<./phylogeni/tree.html>`_
##    Provides basic functions for working with `Tree` and `Node` types such as:
##    - Tree and Node creation
##    - Topology modification
##    - Tree iteration
## 
## `parseNewick<./phylogeni/io/parseNewick.html>`_
##    Provides functions for reading trees from files or strings.
## 
## `writeNewick<./phylogeni/io/writeNewick.html>`_
##    Provides functions for writing trees to files or strings.
## 
## `simulate<./phylogeni/tree.html>`_
##    Provides functions for simulating trees:
##      - Pure birth model
##      - Birth death model
## 
## Generic Node Data
## =================
## `Node` is a generic type which can have any object stored in the data field.  
## 
## One great feature of PhylogeNi is that you do not need to completely rewrite your  
## own parser/writer for custom data types when reading and writing a newick file or string.
## You only need to create `parseAnnotation` and `writeAnnotation` procs to handle 
## reading or writing the annotation string.

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
    var dataCheck = (p: false, ci: false)
    for i in annotations:
      let split = i.split(":")
      doAssert split.len == 2
      case split[0]
      of "p":
        p.currNode.data.posterior = parseFloat(split[1])
        dataCheck.p = true
      of "ci":
        let ci = split[1].split("-")
        doAssert ci.len == 2
        p.currNode.data.credibleInterval = (parseFloat(ci[0]), parseFloat(ci[1]))
        dataCheck.ci = true
      else:
        raise newException(NewickError, "Invalid Annotation")
    if not dataCheck.p or not dataCheck.ci: 
      raise newException(NewickError, "")
  
  proc writeAnnotation(node: Node[CustomData], str: var string) = 
    str.add(fmt"[&p:{$node.data.posterior},ci:{$node.data.credibleInterval.lower}-{$node.data.credibleInterval.upper}]")
  
  let 
    t = treeFromString(treeStr, CustomData) 
    str = t.writeNewickString()
  echo str
  # [&U](B:1.0[&p:0.95,ci:0.9-1.0],C:1.0[&p:0.95,ci:0.9-1.0])A:1.0[&p:0.95,ci:0.9-1.0];

 



