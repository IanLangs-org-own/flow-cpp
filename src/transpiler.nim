import strutils

# ------------------------
# Funciones auxiliares
# ------------------------

# Verifica si un caracter puede ser parte de un identificador
proc isIdent(c: char): bool =
    (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '_'

# Comprueba si la posición 'pos' está escapada dentro de un string/char
proc isEscaped(code: string, pos: int): bool =
    var count = 0
    var p = pos - 1
    while p >= 0 and code[p] == '\\':
        inc(count)
        dec(p)
    return (count mod 2) == 1

# ------------------------
# Función principal
# ------------------------

proc transpileCode*(code: string): string =
    var result = ""          # rename result to avoid shadowing
    var i = 0
    let n = code.len
    var anyInCode = false
    var strInCode = false

    var inString = false
    var inChar = false
    var inLineComment = false
    var inBlockComment = false
    var inInclude = false

    while i < n:
        let c = code[i]
        let next = if i + 1 < n: code[i + 1] else: '\0'

        # Detección de includes
        if not (inString or inChar or inLineComment or inBlockComment) and
             code.substr(i, min(i+7, n-1)) == "#include":
            inInclude = true

        # Fin de estados
        if inInclude and c == '\n': inInclude = false
        if inLineComment and c == '\n': inLineComment = false
        if inBlockComment and c == '*' and next == '/':
            inBlockComment = false
            result.add("*/")
            i += 2
            continue

        # Inicio de comentarios
        if not (inString or inChar or inLineComment or inBlockComment):
            if c == '/' and next == '/': inLineComment = true
            elif c == '/' and next == '*': inBlockComment = true

        # Strings y chars
        if not (inChar or inLineComment or inBlockComment) and c == '"' and not isEscaped(code, i):
            inString = not inString
        if not (inString or inLineComment or inBlockComment) and c == '\'' and not isEscaped(code, i):
            inChar = not inChar

        # Transformaciones Flow-C++ (solo si no estamos dentro de string/char/comentarios/include)
        if not (inString or inChar or inLineComment or inBlockComment or inInclude):

            # Detectar [expr]:Type:? y [expr]:Type:
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
                        let typ  = if k-1 >= typeStart: code[typeStart .. k-1] else: ""
                        if isVerify:
                            result.add(expr & ".type() == typeid(" & typ & ")")
                            i = k + 2
                        else:
                            result.add("std::any_cast<" & typ & ">(" & expr & ")")
                            i = k + 1
                        anyInCode = true
                        continue

            # Regex seguros para palabras clave
            if code.substr(i, min(i+2, n-1)) == "any":
                let prev = if i > 0: code[i-1] else: '\0'
                let nextc = if i+3 < n: code[i+3] else: '\0'
                let inOtherScope = i >= 2 and code.substr(i-2, i-1) == "::"
                if not isIdent(prev) and not isIdent(nextc) and not inOtherScope:
                    result.add "std::any"
                    anyInCode = true
                    i += 3
                    continue

            if code.substr(i, min(i+2, n-1)) == "str":
                let prev = if i > 0: code[i-1] else: '\0'
                let nextc = if i+3 < n: code[i+3] else: '\0'
                let inOtherScope = i >= 2 and code.substr(i-2, i-1) == "::"
                if not isIdent(prev) and not isIdent(nextc) and not inOtherScope:
                    result.add "std::string"
                    strInCode = true
                    i += 3
                    continue

            if code.substr(i, min(i+2, n-1)) == "Cfn":
                let prev = if i > 0: code[i-1] else: '\0'
                let nextc = if i+3 < n: code[i+3] else: '\0'
                let inOtherScope = i >= 2 and code.substr(i-2, i-1) == "::"
                if not isIdent(prev) and not isIdent(nextc) and not inOtherScope:
                    result.add "extern \"C\""
                    i += 3
                    continue

        # Agregar caracter actual
        result.add c
        inc(i)

    # Includes automáticos
    if anyInCode and not result.contains("#include <any>"):
        let lastInclude = result.rfind("#include")
        if lastInclude >= 0:
            let nl = result.find('\n', lastInclude)
            if nl >= 0: result.insert("#include <any>\n", Natural(nl + 1))
            else: result.add("\n#include <any>\n")
        else:
            result = "#include <any>\n" & result

    if strInCode and not (result.contains("#include <string>") or result.contains("#include <iostream>")):
        let lastInclude = result.rfind("#include")
        if lastInclude >= 0:
            let nl = result.find('\n', lastInclude)
            if nl >= 0: result.insert("#include <string>\n", Natural(nl + 1))
            else: result.add("\n#include <string>\n")
        else:
            result = "#include <string>\n" & result

    return result
