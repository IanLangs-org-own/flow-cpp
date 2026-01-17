#include "transpile.hpp"
#include <iostream>
#include <fstream>

std::string version = "1.0.0";

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Uso: tc3p archivo1.c3p [archivo2.c3p ...]\n";
        return 1;
    }

    if (std::string(argv[1]) == "-v" | std::string(argv[1]) == "--version")
        std::cout << "c+++ version = " << version << '\n';

    
    for (int j = 1; j < argc; ++j) {
        std::ifstream in(argv[j]);
        if (!in) {
            std::cerr << "No se pudo abrir el archivo: " << argv[j] << "\n";
            continue; 
        }

        std::string code((std::istreambuf_iterator<char>(in)),
                         std::istreambuf_iterator<char>());

        std::string result = transpile(code);

        std::string outname = argv[j];
        size_t dot = outname.find_last_of('.');
        if (dot != std::string::npos) {
            outname = outname.substr(0, dot);
        }
        outname += ".cpp";

        std::ofstream out(outname);
        if (!out) {
            std::cerr << "No se pudo escribir el archivo: " << outname << "\n";
            continue;
        }
        out << result;

        std::cout << "Transpilado: " << outname << "\n";
    }

    return 0;
}
