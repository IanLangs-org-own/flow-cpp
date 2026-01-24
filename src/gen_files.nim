import os, strutils, sequtils

# ------------------------
# Configuración de rutas
# ------------------------
const
  cacheDir* = "dist/cpp"
  distDir*  = "dist"
  objDir*   = "dist/obj"

# ------------------------
# Funciones de limpieza
# ------------------------
proc removeDirRec(path: string) =
  if not dirExists(path):
    return

  for entry in walkDir(path):
    let fullPath = joinPath(path, entry.path)
    if entry.kind == pcFile:
      removeFile(fullPath)
    elif entry.kind == pcDir:
      removeDirRec(fullPath)

  removeDir(path) # borra la carpeta vacía

# ------------------------
# Crear carpeta limpia
# ------------------------
proc recreateDir(path: string) =
  if dirExists(path): removeDirRec(path)
  createDir(path)

# ------------------------
# Inicialización de directorios (limpio)
# ------------------------
proc initDirs*() =
  for path in @[cacheDir, objDir]:
    recreateDir(path)

# ------------------------
# Generar archivo .cpp
# ------------------------
proc genCppFile*(name, code: string): string =
  let path = cacheDir / (name & ".cpp")
  writeFile(path, code)
  return path
