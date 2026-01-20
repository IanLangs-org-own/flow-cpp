#include "replaceExt.h"
#include <string>
#include <cstring>

const char* replaceExt(const char* path, const char* newExt) {
    std::string s(path);

    size_t dot = s.find_last_of('.');
    if (dot != std::string::npos) {
        s = s.substr(0, dot);
    }

    if (newExt[0] != '.') {
        s += ".";
    }

    s += newExt;

    char* out = new char[s.size() + 1];
    std::memcpy(out, s.c_str(), s.size() + 1);
    return out;
}

void free_replaceExt(const char* s) {
    delete[] s;
}
