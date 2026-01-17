#include <iostream>
int main() {
    any x = "1";
    if ([x]:int:?) std::cout << "x es un int";
    else std::cout << "x no es un int";
    return 0;
}