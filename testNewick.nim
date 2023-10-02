import ./src/phylogeni

var t = parseNewickString("(b:1.0,(d:1.0,(f:1.0,g:1.0)e:1.0)c:1.0)a:1.0;")
echo t.ascii
t.ladderize(Descending)
echo t.ascii

var t2 = parseNewickString("(b:1.0[&&NHX:key=b],(d:1.0[&&NHX:key=d],(f:1.0[&&NHX:key=f],g:1.0[&&NHX:key=g])e:1.0[&&NHX:key=e])c:1.0[&&NHX:key=c])a:1.0[&&NHX:key=a];", DataNode[NHXData])
echo t2.ascii
for i in t2.preorder:
  echo i.data["key"]
