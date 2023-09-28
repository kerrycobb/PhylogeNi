import ./phylogeni

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

# var t = parseNewickString(Nd, "((([Test]f:1.0[Test[Test]],g:1.0[Test])e:1.0[Test],d:1.0[Test])c:1.0[Test],b:1.0[Test])a:1.0[Test];")
var t = parseNewickString(Nd, "(())")
# echo t.ascii
# for i in t.preorder:
#   echo i[]
# t.ladderize()
# echo t.ascii
# prune(t.findNode("f"))
# echo t.ascii
# echo t.writeNewickString()




# echo t.ascii
# for i in t.preorder:
#   echo i.label
# echo ""

# var c = t.getCoords()
# for i in c.preorder():
#   echo i[]
# echo ""

# t.ladderize(Descending)
# echo t.ascii
# var c2 = t.getCoords()
# for i in c2.preorder():
#   echo i[]

