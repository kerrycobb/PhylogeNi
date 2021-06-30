import ../src/phylogeni
import unittest

# TODO: Randomly simulate large batch of trees and ensure that the mean branch length is close to the expectation

suite "Tree Simulation":
  test "pure birth":
    var 
      t = uniformPureBirth(10)
      i = 0
    for l in t.iterleaves():
      i+=1
    check(i == 10)
    

  test "birth death":
    var 
      t = uniformBirthDeath(10, rerun=true)
      i = 0
    for l in t.iterleaves():
      i+=1
    check(i == 10)
 
