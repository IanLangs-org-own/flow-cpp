import os, osproc, strutils, sequtils
import gen_files

# ------------------------
# Archivos .cpp encontrados
# ------------------------
var cppFiles: seq[string] = @[]

# ------------------------
# Crear directorios si no existen
# ------------------------
proc createDirs() =
  for path in @[cacheDir, objDir, distDir]:
    if not dirExists(path):
      createDir(path)

# ------------------------
# Verificar que haya .cpp generados
# ------------------------
proc verify() =
  cppFiles = toSeq(walkFiles(cacheDir / "*.cpp"))
  if cppFiles.len == 0:
    quit("No hay archivos .cpp en dist/cpp/", QuitFailure)

# ------------------------
# Compilar cada .cpp a .o
# ------------------------
proc compileObjs(flags: seq[string]) =
  for cpp in cppFiles:
    let objPath = objDir / cpp.extractFilename.changeFileExt(".o")
    let cmd = @["g++", "-c", cpp, "-o", objPath] & flags
    let res = execCmd(cmd.join(" "))
    if res != 0:
      quit("Error compilando " & cpp, QuitFailure)

# ------------------------
# Linkear todos los objetos a un solo binario
# ------------------------
proc linkObjs(outName: string) =
  let objs = toSeq(walkFiles(objDir / "*.o"))
  if objs.len == 0:
    quit("No hay archivos .o para linkear", QuitFailure)
  let linkCmd = @["g++"] & objs & @["-o", distDir / outName]
  let res = execCmd(linkCmd.join(" "))
  if res != 0:
    quit("Error linkeando", QuitFailure)

# ------------------------
# Función principal: compilar todo
# ------------------------
proc compileAll*(flags: seq[string], outName: string = "app") =
  # Crear carpetas si no existen
  createDirs()

  # Verificar que hay cpp para compilar
  verify()

  # Compilar todos los cpp a objetos
  compileObjs(flags)

  # Linkear los objetos a un binario
  linkObjs(outName)
