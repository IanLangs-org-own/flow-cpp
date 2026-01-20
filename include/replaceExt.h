#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Reemplaza la extensión de un path (ej: "file.c3p" -> "file.cpp")
const char* replaceExt(const char* path, const char* newExt);

// Libera memoria
void free_replaceExt(const char* s);

#ifdef __cplusplus
}
#endif
