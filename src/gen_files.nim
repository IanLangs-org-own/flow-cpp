import os, strutils, sequtils

# ------------------------
# Configuración de rutas
# ------------------------
const
  cacheDir* = "dist/cpp"
  distDir*  = "dist"
  objDir*   = "dist/obj"

# ------------------------
# Crear carpeta si no existe
# ------------------------
proc initDirs*() =
  for path in @[cacheDir, objDir, distDir]:
    if not dirExists(path):
      createDir(path)

# ------------------------
# Generar archivo .cpp solo si no existe
# ------------------------
proc genCppFile*(name, code: string): string =
  let path = cacheDir / (name & ".cpp")
  # Si ya existe, no sobrescribe
  if not fileExists(path):
    writeFile(path, code)
  return path
