#include <flow/types>
#include <iostream>
int main(int argsCount, char** argsValue) {
    flow::any obj = "hola any str many string\n"
              "Flow C++ es este\n";
    std::cout << flow::any_cast<flow::str>(obj) << '\n';
    return 0;
}