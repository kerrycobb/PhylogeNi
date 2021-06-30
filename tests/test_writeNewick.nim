import ../src/phylogeni
import unittest

suite "Newick Writer":
  test "void type":
    let
      a = Node[void](label:"a", length:1.0)
      b = Node[void](label:"b", length:1.0)
      c = Node[void](label:"c", length:1.0)
      d = Node[void](label:"d", length:1.0)
      e = Node[void](label:"e", length:1.0)
      f = Node[void](label:"f", length:1.0)
      g = Node[void](label:"g", length:1.0)
      tree = Tree[void](root: a, rooted:true)
    a.add_child(b)
    a.add_child(c)
    c.add_child(d)
    c.add_child(e)
    e.add_child(f)
    e.add_child(g)
    var 
      s = tree.writeNewickString()
      expected = "[&R](b:1.0,(d:1.0,(f:1.0,g:1.0)e:1.0)c:1.0)a:1.0;" 
    check(s == expected)


  test "string type":
    let
      a = Node[string](label:"a", length:1.0, data:"data")
      b = Node[string](label:"b", length:1.0, data:"data")
      c = Node[string](label:"c", length:1.0, data:"data")
      d = Node[string](label:"d", length:1.0, data:"data")
      e = Node[string](label:"e", length:1.0, data:"data")
      f = Node[string](label:"f", length:1.0, data:"data")
      g = Node[string](label:"g", length:1.0, data:"data")
      tree = Tree[string](root: a, rooted: true)
    a.add_child(b)
    a.add_child(c)
    c.add_child(d)
    c.add_child(e)
    e.add_child(f)
    e.add_child(g)
    var 
      s = tree.writeNewickString()
      expected = "[&R](b:1.0[&data],(d:1.0[&data],(f:1.0[&data],g:1.0[&data])e:1.0[&data])c:1.0[&data])a:1.0[&data];"
    check(s == expected)
