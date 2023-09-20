import ./phylogeni

type
  Nd = ref object
    parent: Nd 
    children: seq[Nd]
    label: string
    length: float
    data: string

proc addChild(parent, child: Nd) = 
  # TODO: Make this a concept once that works 
  parent.children.add(child)
  child.parent = parent

proc writeAnnotation(node: Nd): string = 
  result.add('[')
  result.add(node.data)
  result.add(']')

proc parseAnnotation(node: Nd, str: string) = 
  node.data = str

var t = parseNewickString("(b:1.0,(d:1.0,(f:1.0,g:1.0)e:1.0)c:1.0)a:1.0;", Nd)
echo t.writeNewickString(false)

# Bad newick strings
# TODO: Fix parser to catch these and raise exception with helpful error msg
# var 
  # str = "(B:1.0, [test]C:1.0)A:1.0;" #TODO: Fix error msg
  # str = "(B:1.0,C:[test]1.0)A:1.0;" #TODO: Fix error msg
  # str = "(B:1.0,C:1.0:[test])A:1.0;" #TODO: Fix error msg
  # str = "B:1.0,C:1.0:[test])A:1.0;" #TODO: Fix error msg
  # t = parseNewickString(str, Nd)

echo t.ascii
for i in t.preorder:
  echo i.label
echo ""

var c = t.getCoords()
for i in c.preorder():
  echo i[]
echo ""

t.ladderize(Descending)
echo t.ascii
var c2 = t.getCoords()
for i in c2.preorder():
  echo i[]

