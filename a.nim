import npeg

# proc parse*(T: typedesc, str:string) = 
#   template `>`(a: untyped): untyped = discard
#   let p = peg "parser":
#     parser  <- >"test" 
#   let r = p.match(str)
#   # echo r.captures
# parse(int, "test")

proc parse*[T](o: T, str:string) = 
  template `>`(a: untyped): untyped = discard
  let p = peg "parser":
    parser  <- >"test" 
  let r = p.match(str)
  # echo r.captures
# parse(1, "test")


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