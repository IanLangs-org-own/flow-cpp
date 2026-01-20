#include "transpile.hpp"
#include "tD.hpp"
#include <cstring>

const char* transpile_c(const char* code) {
    std::string result = transpile(code);
    char* cstr = new char[result.size() + 1];
    std::memcpy(cstr, result.c_str(), result.size() + 1);
    return cstr;
}

void free_transpile(const char* s) {
    delete[] s;
}
