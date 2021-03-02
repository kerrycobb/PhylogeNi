# PhylogeNi
A library with some basic functions for working with phylogenetic trees.

This is a Work in progress. Suggestions, contributions, and criticisms are welcome! Breaking changes are likely.

## Installation
Requires Nim to be installed on your system. See https://nim-lang.org/

Installation with the nimble package manager is recommended:

`nimble install phylogeni`


## Usage 

API documentation at https://kerrycobb.github.io/PhylogeNi/

### Construct a tree
```Nim
import phylogeni

let
  a = Node(name: "A")
  b = Node(name: "B")
  c = Node(name: "C")
  d = Node(name: "D")
  e = Node(name: "E")
  f = Node(name: "F")
  g = Node(name: "G")
  tree = Tree(root: a, rooted: true)

a.add_child(b)
a.add_child(c)
c.add_child(d)
c.add_child(e)
e.add_child(f)
e.add_child(g)
```

### Tree Traversals

##### Preorder Traversal
```nim
for i in tree.preorder(): 
  echo i.name
```

##### Postorder Traversal
```nim
for i in tree.postorder(): 
  echo i.name
```

##### Level Order Traversal
```nim
for i in tree.levelorder(): 
  echo i.name
```

##### Newick Order Traversal
Used for generating newick files. A hybrid of preorder and post order traversal
where all internal nodes are visited twice.

```nim
for i in tree.newickorder(): 
  echo "Name: ", i.node.name, ", ", "First visit: ", i.firstVisit   
```

##### Traverse Leaves
```nim
for i in tree.iterleaves(): 
  echo i.name
```

### Ladderize Tree
```nim
tree.ladderize(ascending=false)
for i in tree.preorder(): 
  echo i.name

tree.ladderize(ascending=true)
for i in tree.preorder(): 
  echo i.name
```

### Reading Newick String
```nim
var
  str = "((C:1.0,D:1.0)B:1.0,(F:1.0,G:1.0)E:1.0)A:1.0;"
  tree = parseNewickString(str)
```

### Write Newick String 
```nim
var s = tree.writeNewickString()
```

### Read Newick File
```nim 
var
  tree = parseNewickFile("tree.nwk")
```

### Write Newick File
```nim
tree.writeNewickFile("tree.nwk")
```

### Simulating Trees
##### Yule Pure Birth
```nim
import random
randomize()
var tree = uniformPureBirth(10)
```

##### Birth Death
```nim
import random
randomize()
var tree = uniformBirthDeath(10, rerun=true)
```
