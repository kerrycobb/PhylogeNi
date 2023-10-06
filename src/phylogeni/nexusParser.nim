import npeg
import ./concepts
import ./nodeTypes
import ./newickParser
import std/[tables, strformat, strutils]

type
  NexusKind* = enum nexusData, nexusTaxa, nexusTrees, nexusUndefined

  NexusBlock*[T] = object
    case kind*: NexusKind
    of nexusTrees:
      translate*: OrderedTable[string, string]
      trees*: seq[tuple[label: string, tree:T]]
    of nexusTaxa:
      ntaxa*: int
      taxa*: seq[string]
    of nexusData:
      nchar*: int
    of nexusUndefined:
      blockName*: string
      blockString*: string

  Nexus*[T] = object  
    blocks*: seq[NexusBlock[T]]


# TODO: In the future it should be possible to do this instead of the current
# approach: 
# type Nexus*[T] = distinct seq[NexusBlock[T]] 
# proc len*[T](n: Nexus[T]): int {.borrow.}
# proc `$`*(j:  Nexus[T]): string {.borrow.}
# proc `==`*(a, b:  Nexus[T]): bool {.borrow.}
# proc add*(j: var  Nexus[T], n: int) {.borrow.}
# proc `[]`*(a:  Nexus[T], i: int): int = seq[int](a)[i]
# proc join*(a:  Nexus[T], s: string): string {.borrow.}


proc len*[T](n: Nexus[T]): int = 
  n.blocks.len

proc add*[T](n: var Nexus[T], b: NexusBlock[T]) = 
  n.blocks.add(b)

proc `[]`*[T](n: Nexus[T], i: int): NexusBlock[T] =
  n.blocks[i]

proc `[]=`*[T](n: var Nexus[T], i:int, b: NexusBlock[T]) = 
  n.blocks[i] = b

proc find*[T](n: Nexus[T], b: NexusBlock[T]): int = 
  n.blocks.fid(b)

proc delete*[T](n: var Nexus[T], i: int) = 
  n.blocks.delete(i)

iterator items*[T](n: Nexus[T]): NexusBlock[T] = 
  for i in n.blocks.items: 
    yield i

proc `$`*[T](n: Nexus[T]): string = 
  result.add("Nexus:\n")
  var cnt = 0
  for i in n:
    result.add(&"  {cnt}: {i.kind}\n")
    cnt += 1

template genericBugWorkAround() =
  # Workaround for bug in Nim
  # https://github.com/zevv/npeg/issues/68
  # https://github.com/nim-lang/Nim/issues/22740
  template `>`(a: untyped): untyped = discard
  template `*`(a: untyped): untyped = discard
  template `-`(a: untyped): untyped = discard
  template `+`(a: untyped): untyped = discard
  template `@`(a: untyped): untyped = discard

proc parseDataBlock[T](nex: var Nexus[T], str: string) =  
  # TODO: Work in progress
  var dataBlock = NexusBlock[T](kind:nexusData)
  genericBugWorkAround()
  let p = peg "data":
    s          <- *Space
    S          <- +Space
    nchar      <- S * >i"nchar=" * >+Digit
    ntax       <- S * >i"ntax=" * >+Digit 
    dimensions <- s * >i"dimensions" * ntax * nchar * s * ';'    
    datatype   <- S * >i"datatype=" * >+Alpha 
    missing    <- S * >i"missing=" * >'?'
    gap        <- S * >i"gap=" * >'-'
    dformat    <- s * >i"format" * datatype * missing * gap * s * ';' 
    sample     <- S * >+Alpha * S * >+(Alpha | {'-', '?'}) 
    matrix     <- s * >i"matrix" * +sample * s * ';'
    data       <- dimensions * dformat * matrix
  let r = p.match(str)
  nex.add(dataBlock)

proc parseTaxaBlock[T](nex: var Nexus[T], str: string) =  
  var taxaBlock = NexusBlock[T](kind:nexusTaxa)
  genericBugWorkAround()
  let p = peg "taxa":
    s          <- *Space
    S          <- +Space
    label      <- S * >+(Alnum | {'_', '-'}): 
      taxaBlock.taxa.add(capture[1].s)
    labels     <- i"taxlabels" * +label * s * ';' 
    dimensions <- i"dimensions" * S * i"ntax=" * >*Digit * ';': 
      taxaBlock.ntaxa = parseInt(capture[1].s)
    taxa       <- s * dimensions * S * labels * s * !1 
  let r = p.match(str)
  assert r.ok
  nex.add(taxaBlock)

proc parseTreesBlock[T](nex: var Nexus[T], str: string) =  
  var treeBlock = NexusBlock[T](kind:nexusTrees) 
  genericBugWorkAround()
  let p = peg "trees":
    s         <- *Space
    label     <- *(Alnum | {'_', '.', '-'}) 
    pair      <- s * >?label * s * >label:
      treeBlock.translate[capture[1].s] = capture[2].s 
    paired    <- pair * *(s * ',' * pair)
    translate <- >i"translate" * paired * @';'
    tree      <- s * i"tree" * s * >label * s * '=' * >@';':
      var t = parseNewickString(capture[2].s, T)
      treeBlock.trees.add((capture[1].s, t))
    trees     <- s * ?translate * +tree * s * !1
  let r = p.match(str)
  assert r.ok
  nex.blocks.add(treeBlock)

proc parseUndefinedBlock[T](nex: var Nexus[T], name, str: string) =  
  var undefinedBlock = NexusBlock[T](kind:nexusUndefined) 
  undefinedBlock.blockName = name 
  undefinedBlock.blockString = str 
  nex.blocks.add(undefinedBlock)

proc parseNexusString*(str: string, T: typedesc[TraversableNode] = NexusNode): Nexus[T] =  
  genericBugWorkAround()
  var nex = Nexus[T]() 
  let p = peg "nexus":
    S         <- *Space
    label     <- *(Alnum | {'_', '.', '-'})
    data      <- i"data;" * >*(1-i"end;"):
      parseDataBlock(nex, capture[1].s)
    taxa      <- i"taxa;" * >*(1-i"end;"):  
      parseTaxaBlock(nex, capture[1].s)
    trees     <- i"trees;" * >*(1-i"end;"): 
      parseTreesBlock(nex, capture[1].s)
    undefined <- >+Alpha * ';' * >*(1 - i"end;"):  
      parseUndefinedBlock(nex, capture[1].s, capture[2].s)
    kind      <- (data | taxa | trees | undefined) 
    nblock    <- i"begin" * S * kind * S * i"end;"  
    nexus     <- i"#nexus" * S * nblock * *(S * nblock) * S * !1 
  let r = p.match(str)
  assert r.ok
  result = nex 

proc parseNexusFile*(path: string, T: typedesc[TraversableNode] = NexusNode): Nexus[T] = 
  var str = readFile(path)
  result = parseNexusString(str, T)


# # Used for testing
# var str = """
# #NEXUS
# Begin TAXA;
#   Dimensions ntax=4;
#   TaxLabels SpaceDog SpaceCat SpaceOrc SpaceElf;
# End;

# Begin data;
# dimensions ntax=5 nchar=54;
# format datatype=dna missing=? gap=-;
# matrix
#  Ephedra       TTAAGCCATGCATGTCTAAGTATGAACTAATTCCAAACGGTGAAACTGCGGATG
#  Gnetum        TTAAGCCATGCATGTCTATGTACGAACTAATC-AGAACGGTGAAACTGCGGATG
#  Welwitschia   TTAAGCCATGCACGTGTAAGTATGAACTAGTC-GAAACGGTGAAACTGCGGATG
#  Ginkgo        TTAAGCCATGCATGTGTAAGTATGAACTCTTTACAGACTGTGAAACTGCGAATG
#  Pinus         TTAAGCCATGCATGTCTAAGTATGAACTAATTGCAGACTGTGAAACTGCGGATG
# ;
# End;

# BEGIN TREES;
#   Translate 1 SpaceDog, 2 SpaceCat, 3 SpaceOrc, 4 SpaceElf;
#   Tree tree1 = [&R] (((SpaceDog[&length_range={243.375355,284.829584},height_95%_HPD={1.9999999949504854E-6,6.000000098538294E-6},length_95%_HPD={252.659576,279.50401},length=268.28712902000007,length_median=268.7639845,height_median=4.00000001832268E-6,height_range={2.2737367544323206E-13,6.99999992548328E-6},height=3.8000000552074197E-6],SpaceCat),SpaceOrc,SpaceElf));
# END;

# BEGIN PAUP;
#   Dumb paup commands
# END;
# """

# # import ./traverse

# # var n = parseNexusString(str)
# # var t = n[2].trees[0].tree
# # for i in t.preorder(): 
# #   echo i.data