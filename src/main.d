// src/main.d

import std.stdio : writeln;
import std.file : readText, write;
import core.stdc.string : strlen;
import std.string : toStringz;

extern(C) const(char)* transpile_c(const(char)* code);
extern(C) void free_transpile(const(char)* s);

extern(C) const(char)* replaceExt(const(char)* path, const(char)* newExt);
extern(C) void free_replaceExt(const(char)* s);

string version_c3p = "0.1.2";

void main(string[] args) {
    if (args.length < 2) {
        writeln("Uso: tc3p archivo1.c3p [archivo2.c3p ...]");
        return;
    }

    if (args[1] == "-v" || args[1] == "--version") {
        writeln("c+++ version = ", version_c3p);
        return;
    }

    foreach (j; 1 .. args.length) {
        string filename = args[j];

        string code;
        try {
            code = readText(filename);
        } catch (Exception e) {
            writeln("No se pudo abrir el archivo: ", filename);
            continue;
        }

        // ⚠️ SIEMPRE toStringz
        const(char)* output_c = transpile_c(toStringz(code));
        string result = output_c[0 .. strlen(output_c)].idup;
        free_transpile(output_c);

        const(char)* outname_c = replaceExt(toStringz(filename), "cpp");
        string outname = outname_c[0 .. strlen(outname_c)].idup;
        free_replaceExt(outname_c);

        try {
            write(outname, result);
        } catch (Exception e) {
            writeln("No se pudo escribir el archivo: ", outname);
            continue;
        }

        writeln("Transpilado: ", outname);
    }
}
