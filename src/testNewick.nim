import ./phylogeni

# type
#   Nd* = ref object
#     parent*: Nd
#     children*: seq[Nd]
#     label*: string
#     length*: float
#     data*: string

# proc addChild*(parent, child: Nd) = 
#   ## A bug in Nim currently requires that each type matching that is 
#   ## a TraversableNode must have an addChild proc written for it. 
#   ## This will no longer be necesary when the bug is fixed
#   ## https://github.com/nim-lang/Nim/issues/22723
#   # TODO: Make this a concept once that works 
#   parent.children.add(child)
#   child.parent = parent

# proc parseNewickData*(n: Nd, data: string) = 
#   n.data = data 

# proc writeNewickData*(n: Nd): string = 
#   n.data

# A bug with Npeg prevents this from working
var t = parseNewickString(Nd, "((([Test]f:1.0[Test[Test]],g:1.0[Test])e:1.0[Test],d:1.0[Test])c:1.0[Test],b:1.0[Test])a:1.0[Test];")
# var t = parseNewickString(Nd, "(())")



