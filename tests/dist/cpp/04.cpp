#include <iostream>
#include <any>
int main(int argsCount, char** argsValue) {
    std::any obj = "hola any str many string\n"
              "Flow C++ es este\n";
    std::cout << std::any_cast<std::string>(obj) << '\n';
    return 0;
}