import ./src/phylogeni

# block:
#   var t = parseNewickString("((d:1.0,e:1.0)c:1.0,b:1.0)a:1.0;")
#   echo t.ascii

  # t.ladderize()
  # echo t.ascii
  # echo t.isRoot
  # var 
  #   e = t.find("e")
  # echo e.isLeaf
  # var 
  #   f = NHNode(label:"f", length:1.0)
  #   g = NHNode(label:"g", length:1.0)
  # e.addChild(f)
  # e.addChild(g)
  # echo t.ascii
  # var 
  #   d = t.find("d")
  #   c =  getMRCA(e, d)
  # echo c

  # prune(d)
  # echo t.ascii
  # echo t.writeNewickString()



# block:
#   var 
#     s ="(b:1.0[&&NHX:key=b],(d:1.0[&&NHX:key=d],e:1.0[&&NHX:key=e])c:1.0[&&NHX:key=c])a:1.0[&&NHX:key=a];" 
#     t = parseNewickString(s, NHXNode)
#   echo t.ascii
  # for i in t.preorder():
    # echo i.data["key"]
#     i.data["length"] = $i.length
#   echo t.writeNewickString()

import npeg

# proc parseDataBlock[T](nex: var Nexus[T], str: string) =  
proc parseDataBlock(str: string) =  
  # var dataBlock = NexusBlock[T](kind:nexusData)
  # genericBugWorkAround()
  let p = peg "data":
    s          <- *Space
    S          <- +Space
    # label      <- S * >+(Alnum | '_'): 
    #   taxaBlock.taxa.add(capture[1].s)
    # labels     <- i"taxlabels" * +label * s * ';' 
    # dimensions <- i"dimensions" * S * i"ntax=" * >*Digit * ';': 
    #   taxaBlock.ntaxa = parseInt(capture[1].s)
    nchar      <- S * >i"nchar=" * >+Digit
    ntax       <- S * >i"ntax=" * >+Digit 
    dimensions <- s * >i"dimensions" * ntax * nchar * s * ';'    

    datatype   <- S * >i"datatype=" * >+Alpha 
    missing    <- S * >i"missing=" * >'?'
    gap        <- S * >i"gap=" * >'-'
    format     <- s * >i"format" * datatype * missing * gap * s * ';' 

    sample     <- S * >+Alpha * S * >+(Alpha | {'-', '?'}) 
    matrix     <- s * >i"matrix" * +sample * s * ';'

    data       <- dimensions * format * matrix
  let r = p.match(str)
  echo r.captures
  # nex.add(taxaBlock)



let str = """
dimensions ntax=5 nchar=54;
format datatype=dna missing=? gap=-;
matrix
 Ephedra       TTAAGCCATGCATGTCTAAGTATGAACTAATTCCAAACGGTGAAACTGCGGATG
 Gnetum        TTAAGCCATGCATGTCTATGTACGAACTAATC-AGAACGGTGAAACTGCGGATG
 Welwitschia   TTAAGCCATGCACGTGTAAGTATGAACTAGTC-GAAACGGTGAAACTGCGGATG
 Ginkgo        TTAAGCCATGCATGTGTAAGTATGAACTCTTTACAGACTGTGAAACTGCGAATG
 Pinus         TTAAGCCATGCATGTCTAAGTATGAACTAATTGCAGACTGTGAAACTGCGGATG
;
"""



parseDataBlock(str)
