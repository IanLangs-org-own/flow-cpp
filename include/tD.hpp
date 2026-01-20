#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// recibe C-string, devuelve C-string (allocada con new, liberar con free_transpile)
const char* transpile_c(const char* code);

// libera la memoria devuelta
void free_transpile(const char* s);

#ifdef __cplusplus
}
#endif
