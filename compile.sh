#!/bin/bash

set -e

INCLUDE_DIR="./include"
SRC_DIR="./src"
OUTPUT="ifc"

echo "Compilando C++..."

g++ -I"$INCLUDE_DIR" -c "$SRC_DIR/transpile.cc" -o transpile.o
g++ -I"$INCLUDE_DIR" -c "$SRC_DIR/tD.cc" -o tD.o
g++ -I"$INCLUDE_DIR" -c "$SRC_DIR/replaceExt.cc" -o replaceExt.o

echo "Compilando D y enlazando con C++..."

gdc "$SRC_DIR/main.d" transpile.o tD.o replaceExt.o -o "$OUTPUT" -lstdc++

echo "Compilación finalizada. Ejecutable: ./$OUTPUT"
