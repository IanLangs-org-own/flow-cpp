#include <iostream>
#include <any>
int main() {
    std::any x = "1";
    if (x.type() == typeid(int)) {
        std::cout << "x es un int";
    } else std::cout << "x no es un int";
    return 0;
}