import ../src/phylogeni
import strutils
import unittest

let
  a = Node[void](label:"a")
  b = Node[void](label:"b")
  c = Node[void](label:"c")
  d = Node[void](label:"d")
  e = Node[void](label:"e")
  f = Node[void](label:"f")
  g = Node[void](label:"g")
  tree = Tree[void](root: a, rooted: true)

a.add_child(b)
a.add_child(c)
c.add_child(d)
c.add_child(e)
e.add_child(f)
e.add_child(g)

template toSeq(iter: untyped): untyped = 
  var s: seq[string]  
  for i in iter:
    s.add(i.label)
  s.join(" ") 

suite "Tree Type": 
  test "preorder":
    check(toSeq(tree.preorder) == "a b c d e f g")

  test "postorder":
    check(toSeq(tree.postorder) == "b d f g e c a")

  test "levelorder":
    check(toSeq(tree.levelorder) == "a b c d e f g")
  
  test "inorder":
    check(toSeq(tree.inorder) == "b a d c f e g")

  test "iterleaves":
    check(toSeq(tree.iterleaves) == "b d f g")

  test "newickorder":
    var newickorder: seq[(string, bool)]
    for i in tree.newickorder(): newickorder.add((i.node.label, i.firstVisit))
    check (newickorder == @[("a", true), ("b", true), ("c", true), ("d", true), ("e", true), ("f", true), ("g", true), ("e", false), ("c", false), ("a", false)])

  test "ladderize":
    tree.ladderize(ascending=false)
    check(toSeq(tree.preorder) == "a c e f g d b")
    tree.ladderize()
    check(toSeq(tree.preorder) == "a b c d e f g")

  test "prune":
    tree.prune(e)
    check(toSeq(tree.preorder) == "a b d")



