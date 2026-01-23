import transpiler
import os
import re
import strformat
let argc: int = paramCount()
proc echoORstderr(cond: bool, text:string) =
    if cond: echo text
    else: stderr.write(text)

if argc == 0 or (argc == 1 and commandLineParams()[0] in @["-h", "--help"]):
    echoORstderr(argc == 0,"Uso: ifc file.fcpp [file2.fcpp ...]\nExtensión de archivos de entrada: .fcpp (recomendada), .fcp, .fcc")
    quit(if argc == 0: 1 else: 0)

if argc == 1 and commandLineParams()[0] in @["-v", "--version"]:
    echo "ifc version 1.6\nflow c++ version 1.2"
    quit(0)

func replaceExt(name: string): string =
    replace(name, re"\.fcpp$|\.fcc$|\.fcp$", ".cpp")

type
    FileType = object
        Filename: string
        content: string

func File(file: string): FileType =
    return FileType(Filename: file, content: "")

func File(file: string, cont: string): FileType =
    return FileType(Filename: file, content: cont)

proc write(o: FileType) =
    writeFile(o.Filename, o.content)

proc read(o: var FileType) =
    o.content = readFile(o.Filename)

for arg in commandLineParams():
    if arg[0] == '-':
        stderr.write(fmt"Eror: unknown option {arg}")
        quit(1)

    var file = File(arg)

    file.read()

    file = File(
        replaceExt(arg),
        transpiler.transpileCode(file.content)
    )

    file.write()



