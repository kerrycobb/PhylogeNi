
import ../src/phylogeni

var
  t1Str = "((C:1.0,D:1.0)B:1.0,(F:1.0,G:1.0)E:1.0)A:1.0;"
  t1 = parseNewickString(t1Str)
  n1 = @["A", "B", "C", "D", "E", "F", "G"]
  cnt1 = 0
for i in t1.preorder(): assert(i.name == n1[cnt1]); cnt1 += 1

var str1 = t1.writeNewickString()
assert(str1 == t1Str)
t1.writeNewickFile("test.nwk")

var
  t2 = parseNewickFile("test.nwk")
  n2 = @["A", "B", "C", "D", "E", "F", "G"]
  cnt2 = 0
for i in t2.preorder(): assert(i.name == n2[cnt2]); cnt2 += 1

var
  t3Str = "((C:3.0,D:4.0)B:2.0,(F:5.0,6:1.0)E:7.0)A:1.0;"
  t3 = parseNewickString(t3Str)
  t4Str = t3.writeNewickString()


# Test weird newick strings
# TODO: Add more cases of weird newick strings
var test = parseNewickString("A;") # TODO: Make this work
var test1 = parseNewickString("(A,B,C)D;")
var test2 = parseNewickString("((C)A)B;")



