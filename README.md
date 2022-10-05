![Github Actions CI](https://github.com/kerrycobb/phylogeni/actions/workflows/tests.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Stability](https://img.shields.io/badge/stability-experimental-orange.svg)

# PhylogeNi
PhylogeNi is a Nim library with some basic functions for working with phylogenetic trees.

PhylogeNi is stil a Work in progress. Suggestions, contributions, and criticisms are welcome! Breaking changes are likely.

Read the documentation [here](https://kerrycobb.github.io/PhylogeNi)

## Installation
You will need the Nim compiler to be installed on your system. See https://nim-lang.org/

It is recommended that BioSeq be installed with nimble.

`nimble install phylogeni`


<!-- ## Usage 

API documentation at https://kerrycobb.github.io/PhylogeNi/

### Construct a tree
```Nim
import phylogeni

let
  a = Node[void](label: "A")
  b = Node[void](label: "B")
  c = Node[void](label: "C")
  d = Node[void](label: "D")
  e = Node[void](label: "E")
  f = Node[void](label: "F")
  g = Node[void](label: "G")
  tree = Tree[void](root: a, rooted: true)

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
  echo i.label
```

##### Postorder Traversal
```nim
for i in tree.postorder(): 
  echo i.label
```

##### Level Order Traversal
```nim
for i in tree.levelorder(): 
  echo i.label
```

##### Inorder Traversal
```nim
for i in tree.inorder():
  echo i.label
```

##### Traverse Leaves
```nim
for i in tree.iterleaves(): 
  echo i.label
```

##### Newick Order Traversal
Used for generating newick files. A hybrid of preorder and post order traversal
where all internal nodes are visited twice.
```nim
for i in tree.newickorder(): 
  echo "Name: ", i.node[], ", ", "First visit: ", i.firstVisit   
```

### Ladderize Tree
```nim
tree.ladderize(ascending=false)
for i in tree.preorder(): 
  echo i.label

tree.ladderize(ascending=true)
for i in tree.preorder(): 
  echo i.label
```

### Prune Tree
```nim
tree.prune(e)
for i in tree.preorder():
  echo i.label
```

### Reading Newick String
```nim
var
  tree = Tree[string]()
  str = "[&R]((C:1.0[&data],D:1.0[&data])B:1.0[&data],(F:1.0[&data],G:1.0[&data])E:1.0[&data])A:1.0[&data];"
tree.parseNewickString(str)
```

### Write Newick String 
```nim
var s = tree.writeNewickString()
```

### Read Newick File
```nim 
var
  tree = Tree[void]()
tree.parseNewickFile("tree.nwk")
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
``` -->
