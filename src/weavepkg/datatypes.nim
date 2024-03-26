from std/strutils import parseInt, parseFloat, strip, toBin, startsWith

type
  DatumType* = enum
    INT
    FLOAT
    BOOLEAN
    BIT_VECTOR
  Datum* = ref object
    case dType*: DatumType
    of INT:
      intVal*: int
    of FLOAT:
      floatVal*: float
    of BOOLEAN:
      boolVal*: bool
    of BIT_VECTOR:
      bvVal*: string

proc `$`*(x: Datum): string =
  case x.dType:
    of INT:
      $x.intVal
    of FLOAT:
      $x.floatVal
    of BOOLEAN:
      if x.boolVal: "%t" else: "%f"
    of BIT_VECTOR:
      "%b" & x.bvVal

proc isDecDigit(x: char): bool {.inline.} =
  '0' <= x and x <= '9'

proc isHexDigit(x: char): bool {.inline.} =
  ('0' <= x and x <= '9') or ('a' <= x and x <= 'f') or ('A' <= x and x <= 'F')

proc isValidIntLiteral*(x: string): bool =
  let s = x.strip()
  var i = 0
  let slen = s.len
  if s.startsWith("0b"):
    if slen <= 2: return false
    i = 2
    while i < slen and '0' <= s[i] and s[i] <= '1': i += 1
    if i < slen: return false
  elif s.startsWith("0o"):
    if slen <= 2: return false
    i = 2
    while i < slen and '0' <= s[i] and s[i] <= '7': i += 1
    if i < slen: return false
  elif s.startsWith("0x"):
    if slen <= 2: return false
    i = 2
    while i < slen and s[i].isHexDigit: i += 1
    if i < slen: return false
  elif s == "0": return true
  else:
    if i < slen and (s[i] == '-' or s[i] == '+'): i += 1
    if i >= slen: return false
    while i < slen and '0' <= s[i] and s[i] <= '9': i += 1
    if i < slen: return false
  return true
    
proc isValidFloatLiteral*(x: string): bool =
  let s = x.strip()
  let slen = s.len
  var i = 0
  if i >= slen: return false
  if i < slen and (s[i] == '-' or s[i] == '+'): i += 1
  if i >= slen: return false
  if not s[i].isDecDigit: return false
  if s[i] == '0':
    if i + 1 >= slen or s[i+1] != '.': return false
    i = 2
  while i < slen and s[i].isDecDigit: i += 1
  if i >= slen: return false
  if i < slen and s[i] == '.':
    i += 1
    while i < slen and s[i].isDecDigit: i += 1
  if i < slen and (s[i] == 'e' or s[i] == 'E'):
    i += 1
    if i < slen and (s[i] == '+' or s[i] == '-'): i += 1
    if i >= slen: return false
    while i < slen and s[i].isDecDigit: i += 1
  if i < slen: return false
  return true

proc isValidBooleanLiteral*(x: string): bool =
  let s = x.strip
  s == "%t" or s == "%f"

proc isValidBitVectorLiteral*(x: string): bool =
  let s = x.strip
  let slen = s.len
  for i in 0..<slen:
    if s[i] != '0' and s[i] != '1':
      return false
  return true

proc toIntLiteral*(x: Datum): string =
  case x.dType:
    of INT: $x.intVal
    else: raise newException(ValueError, "Invalid internal value")

proc toFloatLiteral*(x: Datum): string =
  case x.dType:
    of FLOAT: $x.floatVal
    else: raise newException(ValueError, "Invalid internal value")
  
proc parseIntLiteral*(x: string): Datum =
  Datum(dType: INT, intVal: x.strip.parseInt)

proc parseFloatLiteral*(x: string): Datum =
  Datum(dType: FLOAT, floatVal: x.strip.parseFloat)

proc parseBooleanLiteral*(x: string): Datum =
  let s = x.strip
  Datum(dType: BOOLEAN, boolVal: s == "%t" or (s != "%f" and s.len > 0))

proc booleanLiteralAsBoolean*(x: Datum): bool =
  case x.dType:
    of BOOLEAN: x.boolVal
    else: raise newException(ValueError, "Invalid internal value")

proc numericValueAsInt*(x: Datum): int =
  case x.dType:
    of INT: x.intVal
    of FLOAT: x.floatVal.int
    else: raise newException(ValueError, "Invalid internal value")

proc numericValueAsFloat*(x: Datum): float =
  case x.dType:
    of INT: x.intVal.float
    of FLOAT: x.floatVal
    else: raise newException(ValueError, "Invalid internal value")

proc isValidNumericLiteral*(x: string): bool =
  return x.isValidFloatLiteral or x.isValidIntLiteral

proc parseNumericLiteral*(x: string): Datum =
  if x.isValidFloatLiteral:
    x.parseFloatLiteral
  elif x.isValidIntLiteral:
    x.parseIntLiteral
  else:
    raise newException(ValueError, "Invalid internal value")

proc numericValueSmallerThan*(x: Datum, y: Datum): bool =
  if x.dType == INT and x.dType == INT:
    x.intVal < y.intVal
  elif x.dType == INT and x.dType == FLOAT:
    x.intVal.float < y.floatVal
  elif x.dType == FLOAT and x.dType == INT:
    x.floatVal < y.intVal.float
  elif x.dType == FLOAT and x.dType == FLOAT:
    x.floatVal < y.floatVal
  else:
    raise newException(ValueError, "Invalid internal value")

proc numericValueEqualTo*(x: Datum, y: Datum): bool =
  if x.dType == INT and x.dType == INT:
    x.intVal == y.intVal
  elif x.dType == INT and x.dType == FLOAT:
    x.intVal.float == y.floatVal
  elif x.dType == FLOAT and x.dType == INT:
    x.floatVal == y.intVal.float
  elif x.dType == FLOAT and x.dType == FLOAT:
    x.floatVal == y.floatVal
  else:
    raise newException(ValueError, "Invalid internal value")
  
proc numericValueBiggerThan*(x: Datum, y: Datum): bool =
  if x.dType == INT and x.dType == INT:
    x.intVal > y.intVal
  elif x.dType == INT and x.dType == FLOAT:
    x.intVal.float > y.floatVal
  elif x.dType == FLOAT and x.dType == INT:
    x.floatVal > y.intVal.float
  elif x.dType == FLOAT and x.dType == FLOAT:
    x.floatVal > y.floatVal
  else:
    raise newException(ValueError, "Invalid internal value")

proc numericValueSmallerOrEqualThan*(x: Datum, y: Datum): bool =
  x.numericValueEqualTo(y) or x.numericValueSmallerThan(y)

proc numericValueBiggerOrEqualThan*(x: Datum, y: Datum): bool =
  x.numericValueEqualTo(y) or x.numericValueBiggerThan(y)

proc numericValueNotEqualTo*(x: Datum, y: Datum): bool =
  not x.numericValueEqualTo(y)
  
proc toBooleanLiteral*(x: Datum): string =
  case x.dType:
    of BOOLEAN:
      if x.boolVal: "%t" else: "%f"
    else:
      raise newException(ValueError, "Invalid internal value")

# NOTE: the internal representation of bit vector is a string of binary digits;
#       the syntax for a bit vector literal is the prefix "%b" plus a string of
#       binary digits. from now on, all "bitVector" functions deal and return
#       the *internal representation* format (i.e. the one without the "%b" prefix)
#       and all "bitVector*Literal*" functions deal with and return the *literal*
#       format (i.e. the one *with* the "%b" prefix).
  
proc parseBitVectorLiteral*(x: string): Datum =
  let s = x.strip
  Datum(dType: BIT_VECTOR, bvVal: s[2..<s.len])

proc intToBitVectorLiteral*(x: int): string =
  var l = 0
  var z = x
  if z < 0: z = -z; l += 1
  while z >= 0:
    l += 1
    z = z div 2
  "%b" & x.toBin(l)
  
proc toBitVectorLiteral*(x: string): string =
  "%b" & x

proc bitVectorLeftIndex*(x: Datum, v: int): bool =
  case x.dType:
    of BIT_VECTOR:
      x.bvVal[v] == '1'
    else: raise newException(ValueError, "Invalid internal value")

proc bitVectorRightIndex*(x: Datum, v: int): bool =
  case x.dType:
    of BIT_VECTOR:
      bitVectorLeftIndex(x, x.bvVal.len-1-v)
    else: raise newException(ValueError, "Invalid internal value")

proc bitVectorSafeRightIndex(x: Datum, v: int, default: bool): bool =
  case x.dType:
    of BIT_VECTOR:
      if v > x.bvVal.len-1: return default
      else: return x.bitVectorRightIndex(v)
    else: raise newException(ValueError, "Invalid internal value")
  
proc bitVectorAnd*(x: Datum, y: Datum): Datum =
  if x.dType != BIT_VECTOR or y.dType != BIT_VECTOR: raise newException(ValueError, "Invalid internal value")
  let reslen = max(x.bvVal.len, y.bvVal.len)
  var res = ""
  var i = reslen-1
  while i >= 0:
    let left = x.bitVectorSafeRightIndex(i, false)
    let right = x.bitVectorSafeRightIndex(i, false)
    res.add(if left and right: '1' else: '0')
  return Datum(dType: BIT_VECTOR, bvVal: res)
  
proc bitVectorOr*(x: Datum, y: Datum): Datum =
  if x.dType != BIT_VECTOR or y.dType != BIT_VECTOR: raise newException(ValueError, "Invalid internal value")
  let reslen = max(x.bvVal.len, y.bvVal.len)
  var res = ""
  var i = reslen-1
  while i >= 0:
    let left = x.bitVectorSafeRightIndex(i, false)
    let right = x.bitVectorSafeRightIndex(i, false)
    res.add(if left or right: '1' else: '0')
  return Datum(dType: BIT_VECTOR, bvVal: res)

proc bitVectorNot*(x: Datum): Datum =
  if x.dType != BIT_VECTOR: raise newException(ValueError, "Invalid internal value")
  var res = ""
  let xlen = x.bvVal.len
  for i in 0..<xlen:
    res.add(if x.bvVal[i] == '1': '0' else: '1')
  return Datum(dType: BIT_VECTOR, bvVal: res)

proc bitVectorXor*(x: Datum, y: Datum): Datum =
  if x.dType != BIT_VECTOR or y.dType != BIT_VECTOR: raise newException(ValueError, "Invalid internal value")
  let reslen = max(x.bvVal.len, y.bvVal.len)
  var res = ""
  var i = reslen-1
  while i >= 0:
    let left = x.bitVectorSafeRightIndex(i, false)
    let right = x.bitVectorSafeRightIndex(i, false)
    res.add(if (left and not right) or (right and not left) : '1' else: '0')
  return Datum(dType: BIT_VECTOR, bvVal: res)

  
