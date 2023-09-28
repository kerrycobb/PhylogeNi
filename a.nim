# type
#   Node  = concept n, type T 
#     for i in n.children:
#       i is T
#     n.parent is T

#   Nd = ref object
#     parent: Nd
#     children: seq[Nd]

# proc addChild(parent, child: Node) = 
#   parent.children.add(child)
#   child.parent = parent

# var 
#   a = Nd()
#   b = Nd()
# a.addChild(b)
# echo a.children.len



# import npeg


# Wrong number of arguments error
# proc test(T: typedesc, str: string) = 
#   let p = peg "start":
#     start <- >"Test":
#       echo $0
#   var m = p.match(str)
#   echo m.captures
# test(string, "Test")

# # Works
# import npeg
# proc test1(T: typedesc, str: string) = 
#   template `>`(a: untyped): untyped = discard
#   let p = peg "start":
#     start <- >"test"
#   var m = p.match(str)
#   echo m.captures
# test1(string, "test")

# Error: Expected PEG rule name but got nnkSy
# import npeg
# proc test2(T: typedesc, str: string) = 
#   template `>`(a: untyped): untyped = discard
#   let p = peg "start":
#     test   <- >"test"
#     start  <- test
#   var m = p.match(str)
#   echo m.captures
# test2(int, "test")

# # Template does not interfere in non-generic case
# import npeg
# proc test3(str: string) = 
#   template `>`(a: untyped): untyped = discard
#   let p = peg "start":
#     test   <- >"test"
#     start  <- test
#   var m = p.match(str)
#   echo m.captures
# test3("test")


# proc test(T: typedesc, str: string) = 
#   let p = peg "start":
#     start <- "Test"
#   var m = p.match(str)
#   echo m.captures
# test(string, "Test")

# proc test(obj: int, str: string) = 
#   let p = peg "start":
#     start <- >"Test"
#   var m = p.match(str)
#   echo m.captures
# test(1, "Test")

# proc test[T](obj: T, str: string) = 
#   let p = peg "start":
#     start <- "Test"
#   var m = p.match(str)
#   echo m.captures
# test(1, "Test")

import npeg

proc parse*(T: typedesc, str:string) = 
  template `>`(a: untyped): untyped = discard
  let p = peg "parser":
    parser  <- >"test" 
  let r = p.match(str)
  # echo r.captures

# parse(int, "test")

# proc parse*(T: typedesc, str:string) = 
#   template `*`(a: untyped): untyped = discard
#   template `>`(a: untyped): untyped = discard
#   let p = peg "parser":
#     elem  <- internal 
#     internal   <- '(' * >?elem * ')' 
#     parser     <- >internal
#   let r = p.match(str)
#   echo r.captures
# parse(int, "(())")

# proc parse*(str:string) = 
#   let p = peg "parser":
#     elem  <- internal 
#     internal   <- '(' * ?elem * ')' 
#     parser     <- internal
#   let r = p.match(str)
# parse(str)