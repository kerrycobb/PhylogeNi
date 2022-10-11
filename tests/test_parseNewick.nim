import ../src/phylogeni
import unittest
import strutils

template toSeq(iter: untyped, param: untyped): untyped = 
  var s: seq[string]  
  for i in iter:
    s.add($i.param)
  s.join(" ") 

suite "Parse Valid Trees":
  var t = Tree[string]()
  test "valid 1":
    t.parseNewickString(" [&r] (( [comment] C : 1.0 [&data] , D [comment] : 1.0 [&data] )B : [Comment] 1.0 [&data] )A : 1.0 [comment] [&data] ; ")
    check(t.rooted)
    check(toSeq(t.preorder, label) == "A B C D" )
    check(toSeq(t.preorder, length) == "1.0 1.0 1.0 1.0")
    check(toSeq(t.preorder, data) == "data data data data")

  test "valid 2":
    t.parseNewickString(" [&r] (( [&data] C : 1.0 , D [&data] : 1.0 ) B : [&data] 1.0 ) A : 1.0 [&data] ; ")
    check(t.rooted)
    check(toSeq(t.preorder, label) == "A B C D" )
    check(toSeq(t.preorder, length) == "1.0 1.0 1.0 1.0")
    check(toSeq(t.preorder, data) == "data data data data")

  test "valid 3":
    t.parseNewickString(" [&r] ( \"B B\" : 1.0 [&data] , \"C C\" : 1.0 [&data] ) \"A A\" : 1.0  [&data] ; ")
    check(t.rooted)
    check(toSeq(t.preorder, label) == "A A B B C C" )
    check(toSeq(t.preorder, length) == "1.0 1.0 1.0")
    check(toSeq(t.preorder, data) == "data data data")

  # TODO: Write tests for these 
  # echo newTreeFromString(";")
  # echo newTreeFromString("A;")
  # echo newTreeFromString("();")
  # echo newTreeFromString("(B)A;")
  # echo newTreeFromString("(B,C,D)A;")
  # echo newTreeFromString("((D,E)C,B)A;")
  # echo newTreeFromString("((A,B),C);")



test "Parse Invalid Trees":
  var t = Tree[void]()

  proc testParse(str, expected: string) = 
    expect NewickError:
      t.parseNewickString(str)
      let msg = getCurrentExceptionMsg()
      check(msg == expected)
    
  testParse("&r](B,C)A;", "Unexpected character \"]\" at line 1, column 3")
  testParse("[&x](B,C)A;", "Unexpected character \"x\" at line 1, column 3")
  testParse("[&r(B,C)A;", "Expected \"]\" at line 1, column 4")
  testParse("[&r]((B,C,D)A;", "Mismatched parentheses at line 1, column 14")
  testParse("[&r](B\",C)A;", "Unexpected \" at line 1, column 7")
  testParse("[&r](B B,C)A;", "Unexpected character \"B\" at line 1, column 8")
  testParse("[&r](\"B B\"\"B B\",\"C C\")\"A A\";", "Unexpected \" at line 1, column 11")
  testParse("[&r](B,C)A", "Unexpected end of stream at line 1, column 11")
  testParse("[&r](B:1.0,C:1.0)A:1.0", "Unexpected end of stream at line 1, column 23")

  # TODO: Write tests for these 
  # discard newTreeFromString("")
  # discard newTreeFromString("A")
  # discard newTreeFromString("()")
  # discard newTreeFromString("(A,B;")
  # discard newTreeFromString(",;")
    
    
    