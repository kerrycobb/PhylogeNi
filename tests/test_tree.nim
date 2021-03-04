import ../src/phylogeni

# TODO: pruning

let
  a = Node[void](name: "A")
  b = Node[void](name: "B")
  c = Node[void](name: "C")
  d = Node[void](name: "D")
  e = Node[void](name: "E")
  f = Node[void](name: "F")
  g = Node[void](name: "G")
  tree = Tree[void](root: a, rooted: true)

a.add_child(b)
a.add_child(c)
c.add_child(d)
c.add_child(e)
e.add_child(f)
e.add_child(g)

# TODO:
# Check pruning

# Check traversals
var preorder: seq[string]
for i in tree.preorder(): 
  preorder.add(i.name)
assert(preorder == @["A", "B", "C", "D", "E", "F", "G"])

var postorder: seq[string]
for i in tree.postorder(): postorder.add(i.name)
assert (postorder == @["B", "D", "F", "G", "E", "C", "A"])

var levelorder: seq[string]
for i in tree.levelorder(): levelorder.add(i.name)
assert (levelorder == @["A", "B", "C", "D", "E", "F", "G"])

var newickorder: seq[(string, bool)]
for i in tree.newickorder(): newickorder.add((i.node.name, i.firstVisit))
assert (newickorder == @[("A", true), ("B", true), ("C", true), ("D", true), ("E", true), ("F", true), ("G", true), ("E", false), ("C", false), ("A", false)])

var iterleaves: seq[string]
for i in tree.iterleaves(): iterleaves.add(i.name)
assert (iterleaves == @["B", "D", "F", "G"])

# Check ladderizer
tree.ladderize(ascending=false)
var lad_desc: seq[string]
for i in tree.preorder(): lad_desc.add(i.name)
assert(lad_desc == @["A", "C", "E", "F", "G", "D", "B"])

tree.ladderize(ascending=true)
var lad_asc: seq[string]
for i in tree.preorder(): lad_asc.add(i.name)
assert(lad_asc == @["A", "B", "C", "D", "E", "F", "G"])


