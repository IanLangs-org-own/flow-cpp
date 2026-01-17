#include <string>
#include <any>
int main() {
    std::any x = 1;
    auto y = std::any_cast<long long>(x);
    std::string z = "any many";
    std::string many = "";
    return 0;
}