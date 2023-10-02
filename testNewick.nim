import ./src/phylogeni

block:
  var t = parseNewickString("((d:1.0,e:1.0)c:1.0,b:1.0)a:1.0;")
  echo t.ascii
  t.ladderize()
  echo t.ascii
  echo t.isRoot
  var 
    e = t.find("e")
  echo e.isLeaf
  var 
    f = NHNode(label:"f", length:1.0)
    g = NHNode(label:"g", length:1.0)
  e.addChild(f)
  e.addChild(g)
  echo t.ascii
  var 
    d = t.find("d")
    c =  getMRCA(e, d)
  echo c

  prune(d)
  echo t.ascii
  echo t.writeNewickString()



# block:
#   var 
#     s ="(b:1.0[&&NHX:key=b],(d:1.0[&&NHX:key=d],e:1.0[&&NHX:key=e])c:1.0[&&NHX:key=c])a:1.0[&&NHX:key=a];" 
#     t = parseNewickString(s, NHXNode)
#   echo t.ascii
#   for i in t.preorder():
#     echo i.data["key"]
#     i.data["length"] = $i.length
#   echo t.writeNewickString()