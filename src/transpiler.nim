import strutils, tables
# ---------------------------------
# Utilidades léxicas
# ---------------------------------

func isIdentChar(c: char): bool =
  (c >= '0' and c <= '9') or
  (c >= 'A' and c <= 'Z') or
  (c >= 'a' and c <= 'z') or
  c == '_'

func isBoundary(prev, next: char): bool =
  not isIdentChar(prev) and not isIdentChar(next)

proc isEscaped(code: string, pos: int): bool =
  var p = pos - 1
  var count = 0
  while p >= 0 and code[p] == '\\':
    inc count
    dec p
  (count mod 2) == 1

proc isSpace(c: char): bool =
  c in [' ', '\n', '\t', '\v', '\r', '\f']

proc delete_comments(code: string): string =
  var inLineComment = false
  var inBlockComment = false
  var inChar = false
  var inString = false
  var resultCode = newStringOfCap(code.len()) # más eficiente
  var i = 0
  while i < code.len():
    let c = code[i]
    let next = if i + 1 < code.len(): code[i+1] else: '\0'

    # fin de comentarios de línea
    if inLineComment:
      if c == '\n': inLineComment = false
      inc i
      continue

    # fin de comentarios de bloque
    if inBlockComment:
      if c == '*' and next == '/':
        inc i
        inBlockComment = false
      inc i
      continue

    # iniciar comentarios
    if not (inChar or inString):
      if c == '/' and next == '/': inLineComment = true
      elif c == '/' and next == '*': inBlockComment = true

    # toggle de strings/chars
    if c == '"' and not inChar and not isEscaped(code, i):
      inString = not inString
    elif c == '\'' and not inString and not isEscaped(code, i):
      inChar = not inChar

    # agregar solo si no estamos en comentario
    if not inLineComment and not inBlockComment:
      resultCode.add c
    inc i

  return resultCode

# ---------------------------------
# Transpiler principal
# ---------------------------------

proc transpile*(RawCode: string): string =
  var code = delete_comments(RawCode)
  var cppCode = ""
  var i = 0
  let n = code.len()

  var inString = false
  var inChar = false
  var inInclude = false

  var flowUsed = false

  # stack de paréntesis para until/unless
  var pendingUntil = 0
  var parenDepth = 0

  let typeMap = {
    "str": "flow::str",
    "wstr": "flow::wstr",
    "any": "flow::any"
  }.toTable

  while i < n:
    let c = code[i]
    let next = if i + 1 < n: code[i + 1] else: '\0'

    # ------------------------------
    # Strings / chars
    # ------------------------------
    if c == '"' and not inChar and not isEscaped(code, i):
      inString = not inString
    elif c == '\'' and not inString and not isEscaped(code, i):
      inChar = not inChar

    # ------------------------------
    # Includes
    # ------------------------------
    if not (inString or inChar):
      if code.substr(i, min(i+7, n-1)) == "#include":
        inInclude = true
    if inInclude and c == '\n':
      inInclude = false

    # ------------------------------
    # Flow transforms
    # ------------------------------
    if not (inString or inChar or inInclude):

      # [expr]:Type: / ?
      if c == '[':
        var j = i + 1
        var depth = 1
        var localString = false
        var localChar = false

        while j < n and depth > 0:
          let cj = code[j]
          if cj == '"' and not localChar and not isEscaped(code, j):
            localString = not localString
          elif cj == '\'' and not localString and not isEscaped(code, j):
            localChar = not localChar
          elif not (localString or localChar):
            if cj == '[': inc depth
            elif cj == ']': dec depth
          inc j

        if depth == 0 and j < n and code[j] == ':':
          let typeStart = j + 1
          var k = typeStart
          while k < n and code[k] != ':' and code[k] != '\n':
            inc k

          if k < n and code[k] == ':':
            let verify = (k + 1 < n and code[k + 1] == '?')
            let expr = code[i+1 .. j-2]
            let rawType = code[typeStart .. k-1]
            let typ = typeMap.getOrDefault(rawType, rawType)

            if verify:
              cppCode.add(expr & ".type() == typeid(" & typ & ")")
              i = k + 2
            else:
              cppCode.add("flow::any_cast<" & typ & ">(" & expr & ")")
              i = k + 1

            flowUsed = true
            continue

      # until
      if code.substr(i, min(i+4, n-1)) == "until":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+5 < n: code[i+5] else: '\0'
        if isBoundary(prev, nextc):
          cppCode.add "while (!"
          pendingUntil.inc
          i += 5
          continue

      # unless
      if code.substr(i, min(i+5, n-1)) == "unless":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+6 < n: code[i+6] else: '\0'
        if isBoundary(prev, nextc):
          cppCode.add "if (!"
          pendingUntil.inc
          i += 6
          continue
      let kws = [
        ("any",  "flow::any"),
        ("anyP", "flow::anyP"),
        ("str",  "flow::str"),
        ("wstr", "flow::wstr")
      ]
      # any / str / wstr
      var replaced = false
      for (kw, repl) in kws:
        if code.substr(i, min(i+kw.len()-1, n-1)) == kw:
          let prev = if i > 0: code[i-1] else: '\0'
          let nextc = if i+kw.len() < n: code[i+kw.len()] else: '\0'
          if isBoundary(prev, nextc):
            cppCode.add repl
            flowUsed = true
            i += kw.len()
            replaced = true
            break
      if replaced: continue

      # Cfn
      if code.substr(i, min(i+2, n-1)) == "Cfn":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc = if i+3 < n: code[i+3] else: '\0'
        if isBoundary(prev, nextc):
          cppCode.add "extern \"C\""
          i += 3
          continue
      
      #defer
      if code.substr(i, min(i+4, n-1)) == "defer":
        let prev = if i > 0: code[i-1] else: '\0'
        let nextc =  if i+5 < n: code[i+5] else: '\0'

        if isBoundary(prev, nextc):
          var exprBegin = i+6
          var existExprBegin = false

          var exprEnd = i+6
          var existExprEnd = false

          for k in i+6.. n:
            if not (code[k] in [' ', '\n', '\t']):
              existExprBegin = true
              exprBegin = k
              break

          for k in exprBegin.. n:
            if code[k] == ';': 
              existExprEnd = true
              exprEnd = k
              break

          if existExprBegin and existExprEnd:
            cppCode.add "flow::Defer([&](){" & code[exprBegin.. exprEnd] & "})"
            i = exprEnd
          else:
            cppCode.add "flow::Defer()"
          continue



    # ------------------------------
    # Paréntesis
    # ------------------------------
    if c == '(':
      inc parenDepth
    elif c == ')':
      dec parenDepth
      if pendingUntil > 0 and parenDepth == 0:
        cppCode.add "))"
        dec pendingUntil
        inc i
        continue

    cppCode.add c
    inc i

  # ------------------------------
  # Include automático
  # ------------------------------
  if flowUsed and not cppCode.contains("#include <flow/types>"):
    cppCode = "#include <flow/types>\n" & cppCode

  cppCode
