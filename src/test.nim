import ./phylogeni

type
  Nd* = ref object
    parent*: Nd
    children*: seq[Nd]
    label*: string
    length*: float

proc addChild*(parent, child: Nd) = 
  ## A bug in Nim currently requires that each type matching that is 
  ## a TraversableNode must have an addChild proc written for it. 
  ## This will no longer be necesary when the bug is fixed
  ## https://github.com/nim-lang/Nim/issues/22723
  # TODO: Make this a concept once that works 
  parent.children.add(child)
  child.parent = parent

# var t = parseNewickString(Nd, "(((f:1.0,g:1.0)e:1.0,d:1.0)c:1.0,b:1.0)a:1.0;")
# echo t.ascii
# for i in t.preorder:
#   echo i.label
# t.ladderize()
# echo t.ascii
# prune(t.findNode("f"))
# echo t.ascii
# echo t.writeNewickString()

# # TODO: Write tests to ensure all of these fail. 
# discard parseNewickString(Nd, "(B:1.0, [test]C:1.0)A:1.0;")
# discard parseNewickString(Nd, "(B:1.0,C:[test]1.0)A:1.0;")
# discard parseNewickString(Nd, "(B:1.0,C:1.0:[test])A:1.0;") # This is not caught as an exception 
# discard parseNewickString(Nd, "B:1.0,C:1.0:[test])A:1.0;") # This is not caught as an exception
# discard parseNewickString(Nd, "B:1.0[test]") # This is not caught as an exception

# echo parseNewickString(Nd, "B:1.0[test]").ascii



# type
#   Nd*[T] = ref object
#     parent*: Nd[T]
#     children*: seq[Nd[T]]
#     label*: string
#     length*: float
#     data*: T 

# proc addChild*[T](parent, child: Nd[t]) = 
#   # TODO: Make this a concept once that works 
#   parent.children.add(child)
#   child.parent = parent

# proc writeAnnotation*[void](node: Nd[T]): string = 
#   result.add('[')
#   result.add(node.data)
#   result.add(']')

# proc parseAnnotation(node: Nd, str: string) = 
#   node.data = str

# var t = parseNewickString("(b:1.0,(d:1.0,(f:1.0,g:1.0)e:1.0)c:1.0)a:1.0;", Nd)
# echo t.writeNewickString(false)

# # Bad newick strings
# # TODO: Fix parser to catch these and raise exception with helpful error msg
# # var 
#   # str = "(B:1.0, [test]C:1.0)A:1.0;"
#   # str = "(B:1.0,C:[test]1.0)A:1.0;"
#   # str = "(B:1.0,C:1.0:[test])A:1.0;"
#   # str = "B:1.0,C:1.0:[test])A:1.0;"
#   # t = parseNewickString(str, Nd)

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

