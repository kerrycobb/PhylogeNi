import random, math
import ./tree

# TODO: Simulate contained coalescent trees
# TODO: Make option to take random number generator object as an option


# Code for adding generic type to node
# type
#   BirthDeathData* = ref object
#     name*: string
#     length*: float
#     extinct*: bool

# proc writeNewickDataString*(data: BirthDeathData, str: var string) =
#   str.add(data.name)
#   str.add(":")
#   str.add($data.length)
#   str.add("[extinct=")
#   str.add($data.extinct)
#   str.add("]")

proc randExp(l: float): float =
  -ln(rand(1.0))/l

#TODO Why cant I remove the parameter fro unfiromPureBirth and just instead of T use void everywhere
proc uniformPureBirth*(nTips: int, birthRate=1.0): Tree[void] =
  ## Simulate tree under uniform pure birth process
  var
    t = Tree[void](root: Node[void]())
    leaves = @[t.root]
  for i in 1 ..< nTips:
    var
      waitTime = randExp(float(leaves.len()) * birthRate)
      rLeaf = rand(leaves.len - 1)
    # Add wait time to all leaves
    for node in leaves:
      node.length += waitTime
    # Add descendant nodes to random leaf
    for i in 0..1:
      var nd = Node[void]()
      leaves[rLeaf].addChild(nd)
      leaves.add(nd)
    # Delete random leaf from leaf list
    leaves.delete(rLeaf)
  # Add additional length and tip labels to final leaves
  var
    waitTime = randExp(float(leaves.len()) * birthRate)
    inc = 1
  for node in leaves:
    node.length += waitTime
    node.name = "T" & $inc
    inc += 1
  result = t

proc uniformBirthDeath*(nTips: int, birthRate=1.0, deathRate=1.0, rerun=false): Tree[void] =
  ## Simulate tree under uniform birth death process
  var
    t = Tree[void](root: Node[void]())
    leaves = @[t.root]
  while true:
    if leaves.len() == nTips:
      break
    var
      waitTime = randExp(float(leaves.len()) * (birthRate + deathRate))
      rLeaf = rand(leaves.len - 1)
    # Add wait time to all leaves
    for node in leaves:
      node.length += waitTime
    # Determine if speciation or extinction even
    if rand(1.0) < birthRate / (birthRate + deathRate):
      # Speciation event
      for i in 0..1:
        var nd = newNode[void]()
        leaves[rLeaf].addChild(nd)
        leaves.add(nd)
    else:
      # Extinction event
      if leaves.len() == 1:
        # Rerun
        if rerun:
          leaves.add(t.root)
        # Or quit
        else:
          break
      else:
        t.prune(leaves[rLeaf])
    # Delete random leaf from leaf list
    leaves.delete(rLeaf)
  # Add additional length and tip labels to final leaves
  var
    waitTime = randExp(float(leaves.len()) * birthRate)
    inc = 1
  for node in leaves:
    node.length += waitTime
    node.name = "T" & $inc
    inc += 1
  result = t

