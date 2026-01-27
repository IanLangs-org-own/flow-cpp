import strutils, tables

# ------------------------
# Funciones auxiliares
# ------------------------

func isIdent(c: char): bool =
  (c >= '0' and c <= '9') or
  (c >= 'A' and c <= 'Z') or
  (c >= 'a' and c <= 'z') or
  c == '_'

func isOperator(c: char): bool =
  c in ['+','-','<','>','*','/','=','!','&','|']

proc isEscaped(code: string, pos: int): bool =
  var count = 0
  var p = pos - 1
  while p >= 0 and code[p] == '\\':
    inc(count)
    dec(p)
  (count mod 2) == 1

# ------------------------
# Transpiler principal
# ------------------------

proc transpile*(code: string): string =
  var cppCode = ""
  var i = 0
  let n = code.len

  var flowInCode = false

  var inString = false
  var inChar = false
  var inLineComment = false
  var inBlockComment = false
  var inInclude = false

  # Parentesis pendientes para until/unless
  var pendingClose = 0

  while i < n:
    let c = code[i]
    let next = if i + 1 < n: code[i + 1] else: '\0'

    # ----------------------
    # Includes
    # ----------------------
    if not (inString or inChar or inLineComment or inBlockComment) and
       code.substr(i, min(i+7, n-1)) == "#include":
      inInclude = true

    if inInclude and c == '\n': inInclude = false
    if inLineComment and c == '\n': inLineComment = false

    if inBlockComment:
      cppCode.add(c)
      if c == '*' and next == '/':
        cppCode.add(next)       # agregamos la barra final del cierre
        inBlockComment = false
        inc(i)                  # saltamos el next ya copiado
      inc(i)
      continue

    if not (inString or inChar or inLineComment or inBlockComment):
      if c == '/' and next == '/': inLineComment = true
      elif c == '/' and next == '*': inBlockComment = true

    # ----------------------
    # Strings y chars
    # ----------------------
    if not (inChar or inLineComment or inBlockComment) and c == '"' and not isEscaped(code, i):
      inString = not inString
    if not (inString or inLineComment or inBlockComment) and c == '\'' and not isEscaped(code, i):
      inChar = not inChar

    # ----------------------
    # Transformaciones Flow-C++
    # ----------------------
    if not (inString or inChar or inLineComment or inBlockComment or inInclude):

      # [expr]:Type:  /  [expr]:Type:?
      if c == '[':
        var j = i + 1
        var depth = 1
        while j < n and depth > 0:
          if code[j] == '[': inc(depth)
          elif code[j] == ']': dec(depth)
          inc(j)

        if depth == 0 and j < n and code[j] == ':':
          let typeStart = j + 1
          var k = typeStart
          while k < n and code[k] != ':' and code[k] != '\n': inc(k)

          if k < n and code[k] == ':':
            let isVerify = k + 1 < n and code[k + 1] == '?'
            let expr = if j-2 >= i+1: code[i+1 .. j-2] else: ""
            let rawType = if k-1 >= typeStart: code[typeStart .. k-1] else: ""

            let typeMap = toTable({
              "str": "std::string",
              "any": "std::any"
            })

            let typ = typeMap.getOrDefault(rawType, rawType)

            if isVerify:
              cppCode.add(expr & ".type() == typeid(" & typ & ")")
              i = k + 2
            else:
              cppCode.add("flow::any_cast<" & typ & ">(" & expr & ")")
              i = k + 1

            flowInCode = true
            continue

      # any
      if code.substr(i, min(i+2, n-1)) == "any":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+3 < n: code[i+3] else: '\0'
        let scoped = i >= 2 and code.substr(i-2, i-1) == "::"
        if not isIdent(prev) and not isIdent(nextc) and not scoped:
          cppCode.add("flow::any")
          flowInCode = true
          i += 3
          continue

      # str
      if code.substr(i, min(i+2, n-1)) == "str":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+3 < n: code[i+3] else: '\0'
        let scoped = i >= 2 and code.substr(i-2, i-1) == "::"
        if not isIdent(prev) and not isIdent(nextc) and not scoped:
          cppCode.add("flow::str")
          flowInCode = true
          i += 3
          continue
      
      if code.substr(i, min(i+3, n-1)) == "wstr":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+4 < n: code[i+3] else: '\0'
        let scoped = i >= 2 and code.substr(i-2, i-1) == "::"
        if not isIdent(prev) and not isIdent(nextc) and not scoped:
          cppCode.add("flow::wstr")
          flowInCode = true
          i += 3
          continue

      # Cfn
      if code.substr(i, min(i+2, n-1)) == "Cfn":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+3 < n: code[i+3] else: '\0'
        if not isIdent(prev) and not isIdent(nextc):
          cppCode.add("extern \"C\"")
          i += 3
          continue

      # until
      if code.substr(i, min(i+4, n-1)) == "until":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+5 < n: code[i+5] else: '\0'
        if not isIdent(prev) and not isIdent(nextc):
          cppCode.add("while (!")
          pendingClose.inc
          i += 5
          continue

      # unless
      if code.substr(i, min(i+5, n-1)) == "unless":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+6 < n: code[i+6] else: '\0'
        if not isIdent(prev) and not isIdent(nextc):
          cppCode.add("if (!")
          pendingClose.inc
          i += 6
          continue

    # ----------------------
    # Cierre automático de paréntesis para until/unless
    # ----------------------
    if pendingClose > 0 and c == ')':
      pendingClose.dec
      cppCode.add("))")
      inc(i)
      continue

    cppCode.add(c)
    inc(i)

  # ----------------------
  # Includes automáticos
  # ----------------------
  if flowInCode and not cppCode.contains("#include <flow/types>"):
    cppCode = "#include <flow/types>\n" & cppCode

  return cppCode
