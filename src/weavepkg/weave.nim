import std/tables
from std/strutils import join
import ./datatypes

type
  ActivePiece = object
    str: string
    i: int
    lenx: int

proc `$`(x: ActivePiece): string =
  "ActivePiece(str:" & x.str & ",i:" & $x.i & ",lenx:" & $x.lenx & ")"

type
  MacroPieceType = enum
    M_STRING
    M_GAP
  MacroPiece = ref object
    case mpType: MacroPieceType
    of M_STRING:
      strVal: string
    of M_GAP:
      gapNum: int

proc `$`(x: MacroPiece): string =
  case x.mpType:
    of M_GAP:
      "<" & $x.gapNum & ">"
    of M_STRING:
      x.strVal
    
var neutral: string = ""
var active: seq[ActivePiece] = @[]
var defs: TableRef[string,seq[MacroPiece]] = newTable[string,seq[MacroPiece]]()
var line = 0
var col = 0
var errorStack: seq[(int, int, string)] = @[]
type
  CallArg = object
    st: int
    e: int
var callStack: seq[seq[CallArg]] = @[]

proc reportError*(): void =
  for stk in errorStack:
    echo "(" & $(stk[0]+1) & "," & $(stk[1]+1) & "): " & stk[2]

proc registerError(reason: string): void =
  errorStack.add((line, col, reason))

proc updateLineColWith(x: char): void =
  # NOTE: we don't update line&col when inside a function call.
  if active.len() > 1: return
  if x in "\n\v\f":
    line += 1
    col = 0
  else:
    col += 1

proc `$`(x: CallArg): string =
  "CallArg(st:" & $x.st & "," & $x.e & ")"

proc makeMacro(body: string, argList: seq[string]): seq[MacroPiece] =
  var res: seq[MacroPiece] = @[]
  var i = 0
  let lenx = body.len
  let lenarg = argList.len
  var currentText: string = ""
  while i < lenx:
    var argI = 0
    var found = false
    while i < lenx and argI < lenarg:
      let pat = argList[argI]
      if i+pat.len < lenx and body[i..<i+pat.len] == pat:
        if currentText.len > 0:
          res.add(MacroPiece(mpType: M_STRING, strval: currentText))
        currentText = ""
        res.add(MacroPiece(mpType: M_GAP, gapNum: argI))
        i += pat.len
        found = true
        break
      argI += 1
    if found: continue
    else:
      currentText.add(body[i])
      i += 1
  if currentText.len > 0:
    res.add(MacroPiece(mpType: M_STRING, strVal: currenttext))
  return res

proc fillMacro(x: seq[MacroPiece], args: seq[string]): string =
  var res: seq[string] = @[]
  for p in x:
    case p.mpType:
      of M_STRING:
        res.add(p.strval)
      of M_GAP:
        res.add(args[p.gapNum+1])
  return res.join("")

    
proc performCall(call: seq[CallArg]): string =
  # NOTE: this func shall truncate neutral.
  if call.len() <= 0: return ""
  var args: seq[string] = @[]
  let neutralStart = call[0].st
  for callArg in call:
    args.add(neutral[callArg.st..<callArg.e])
  echo args
  neutral = neutral[0..<neutralStart]
  var callRes = ""
  case args[0]:
    of "print":
      echo args[1..<args.len].join
      callRes = ""
    of "error":
      registerError("User Error - " & args[1])
      callRes = ""
      
    of "+":
      block e:
        var callArgs: seq[Datum] = @[]
        var shouldBeFloat = false
        for i in args[1..<args.len]:
          if not (i.isValidIntLiteral or i.isValidFloatLiteral):
            registerError("Invalid type of argument \"" & i & "\"")
            break e
          if i.isValidFloatLiteral:
            shouldBeFloat = true
          callArgs.add(if i.isValidFloatLiteral: i.parseFloatLiteral else: i.parseIntLiteral)
        if shouldBeFloat:
          var sum: float = 0
          for i in callArgs:
            sum = sum + i.numericValueAsFloat
          callRes = Datum(dType: FLOAT, floatVal: sum).toFloatLiteral
        else:
          var sum: int = 0
          for i in callArgs:
            sum = sum + i.numericValueAsInt
          callRes = Datum(dType: INT, intVal: sum).toIntLiteral

    of "-":
      block e:
        var callArgs: seq[Datum] = @[]
        var shouldBeFloat = false
        for i in args[1..<args.len]:
          if not (i.isValidIntLiteral or i.isValidFloatLiteral):
            registerError("Invalid type of argument \"" & i & "\"")
            break e
          if i.isValidFloatLiteral:
            shouldBeFloat = true
          callArgs.add(if i.isValidFloatLiteral: i.parseFloatLiteral else: i.parseIntLiteral)
        if shouldBeFloat:
          var sum: float = callArgs[0].numericValueAsFloat
          for i in callArgs[1..<callArgs.len]:
            sum = sum - i.numericValueAsFloat
          callRes = Datum(dType: FLOAT, floatVal: sum).toFloatLiteral
        else:
          var sum: int = callArgs[0].numericValueAsInt
          for i in callArgs[1..<callArgs.len]:
            sum = sum - i.numericValueAsInt
          callRes = Datum(dType: INT, intVal: sum).toIntLiteral

    of "*":
      block e:
        var callArgs: seq[Datum] = @[]
        var shouldBeFloat = false
        for i in args[1..<args.len]:
          if not (i.isValidIntLiteral or i.isValidFloatLiteral):
            registerError("Invalid type of argument \"" & i & "\"")
            break e
          if i.isValidFloatLiteral:
            shouldBeFloat = true
          callArgs.add(if i.isValidFloatLiteral: i.parseFloatLiteral else: i.parseIntLiteral)
        if shouldBeFloat:
          var product: float = 1
          for i in callArgs:
            product = product * i.numericValueAsFloat
          callRes = Datum(dType: FLOAT, floatVal: product).toFloatLiteral
        else:
          var product: int = 1
          for i in callArgs:
            product = product * i.numericValueAsInt
          callRes = Datum(dType: INT, intVal: product).toIntLiteral

    of "/":
      block e:
        var callArgs: seq[Datum] = @[]
        for i in args[1..<args.len]:
          if not (i.isValidIntLiteral or i.isValidFloatLiteral):
            registerError("Invalid type of argument \"" & i & "\"")
            break e
          callArgs.add(if i.isValidFloatLiteral: i.parseFloatLiteral else: i.parseIntLiteral)
        var product: float = 1
        for i in callArgs:
          product = product / i.numericValueAsFloat
        callRes = Datum(dType: FLOAT, floatVal: product).toFloatLiteral

    of "%":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let a1 = args[1].parseIntLiteral.intVal
        let a2 = args[2].parseIntLiteral.intVal
        callRes = Datum(dType: INT, intVal: a1 mod a2).toIntLiteral
        
    of "<=":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueSmallerOrEqualThan(y)).toBooleanLiteral

    of ">=":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueBiggerOrEqualThan(y)).toBooleanLiteral
        
    of "=":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueEqualTo(y)).toBooleanLiteral
        
    of "!=":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueNotEqualTo(y)).toBooleanLiteral
        
    of "<":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueSmallerThan(y)).toBooleanLiteral
        
    of ">":
      block e:
        if args.len > 3:
          registerError("Arity error; 2 arguments expected but " & $(args.len-1) & " received.")
          break e
        if not args[1].isValidIntLiteral and not args[1].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[1] & "\"")
          break e
        if not args[2].isValidIntLiteral and not args[2].isValidFloatLiteral:
          registerError("Invalid type of argument \"" & args[2] & "\"")
          break e
        let x = if args[1].isValidFloatLiteral:
                  args[1].parseFloatLiteral
                else:
                  args[1].parseIntLiteral
        let y = if args[2].isValidFloatLiteral:
                  args[2].parseFloatLiteral
                else:
                  args[2].parseIntLiteral
        callRes = Datum(dType: BOOLEAN,
                        boolVal: x.numericValueBiggerThan(y)).toBooleanLiteral

    of "cond":
      block e:
        if args.len < 3:
          registerError("Arity error; at least one full clause expected.")
          break e
        var i = 1
        while i < args.len and i+1 < args.len:
          if not args[i].isValidBooleanLiteral:
            registerError("Invalid clause condition; must be boolean.")
            break e
          let verdict = args[i].parseBooleanLiteral.booleanLiteralAsBoolean
          if verdict:
            callRes = args[i+1]
            break e
          i += 2

    of "defn":
      block e:
        if args.len < 3:
          registerError("Arity error; at least a name and a body expected.")
          break e
        let name = args[1]
        let body = args[^1]
        let fnArgs = args[2..<args.len-1]
        let m = makeMacro(body, fnArgs)
        echo m
        defs[name] = m
        
    else:
      if defs.hasKey(args[0]):
        let m = defs[args[0]]
        callRes = m.fillMacro(args)
      else:
        registerError("Cannot find definition of \"" & args[0] & "\"")
        callRes = ""
      
  return callRes

proc exec*(): void =
  block programLoop:
    while active.len() > 0:
      let x = active[^1].str
      let lenx = active[^1].lenx
      var i = active[^1].i
      if i >= lenx:
        discard active.pop()
        continue
      block activePieceLoop:
        while i < lenx:
          updateLineColWith(x[i])
          if x[i] in " \n\r\t\b\v\f":
            if callStack.len() > 0 and callStack[^1].len() > 0 and callStack[^1][^1].e == -1:
              callStack[^1][^1].e = neutral.len()
            while i < lenx and x[i] in " \n\r\t\b\v\f":
              updateLineColWith(x[i])
              i += 1
            continue
          if callStack.len() > 0 and callStack[^1].len() > 0 and callStack[^1][^1].e != -1:
            callStack[^1].add(CallArg(st: neutral.len(), e: -1))
          case x[i]:
            of '@':
              i += 1
              if i >= lenx:
                registerError("No character to escape")
                break programLoop
              neutral.add(x[i])
              updateLineColWith(x[i])
              i += 1
            of '{':
              i += 1
              if i >= lenx:
                registerError("No character to escape")
                break programLoop
              updateLineColWith('{')
              var cnt: int = 0
              var escaped = false
              while i < lenx and cnt >= 0:
                if escaped:
                  neutral.add(x[i])
                  updateLineColWith(x[i])
                  i += 1
                  escaped = false
                  continue
                case x[i]:
                  of '}':
                    cnt -= 1
                    if cnt >= 0: neutral.add(')')
                    updateLineColWith('}')
                    i += 1
                  of '{':
                    neutral.add('{')
                    updateLineColWith('{')
                    cnt += 1
                    i += 1
                  of '@':
                    escaped = true
                    updateLineColWith('@')
                    i += 1
                  else:
                    neutral.add(x[i])
                    updateLineColWith(x[i])
                    i += 1
              if cnt >= 0:
                registerError("Escape sequence ended prematurely; right curly braces required.")
                break programLoop
            of '#':
              i += 1
              if i >= lenx:
                registerError("No character to escape")
                break programLoop
              if x[i] != '(':
                neutral.add('#')
                continue
              neutral.add('(')
              updateLineColWith('(')
              i += 1
              var cnt: int = 0
              var escaped = false
              while i < lenx and cnt >= 0:
                updateLineColWith(x[i])
                if escaped:
                  neutral.add(x[i])
                  i += 1
                  escaped = false
                  continue
                case x[i]:
                  of ')':
                    neutral.add(')')
                    cnt -= 1
                    i += 1
                  of '(':
                    neutral.add('(')
                    cnt += 1
                    i += 1
                  of '@':
                    i += 1
                    escaped = true
                  else:
                    neutral.add(x[i])
                    i += 1
              if cnt >= 0:
                registerError("Escape sequence ended prematurely; right parenthesis required.")
                break programLoop
            of '(':
              i += 1
              callStack.add(@[CallArg(st: neutral.len(), e: -1)])
            of ')':
              i += 1
              active[^1].i = i
              if callStack.len() <= 0:
                registerError("Unbalanced parentheses.")
                break programLoop
              var call = callStack.pop()
              if call.len() <= 0:
                registerError("Invalid call syntax.")
                break programLoop
              call[^1].e = neutral.len()
              let callRes = performCall(call)
              if callRes.len() > 0:
                active.add(ActivePiece(str:callRes, i:0, lenx:callRes.len()))
                break activePieceLoop
            of '}':
              registerError("Invalid escape sequence.")
              break programLoop
            else:
              neutral.add(x[i])
              i += 1
        active[^1].i = i
    if callStack.len > 0:
      registerError("Unbalanced parentheses.")

              
proc load*(x: string): void =
  line = 0
  col = 0
  neutral = ""
  active.add(ActivePiece(str: x, i: 0, lenx: x.len))

  
