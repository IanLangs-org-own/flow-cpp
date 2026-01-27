#include <flow/types>
int main() {
    flow::any x = 1;
    auto y = flow::any_cast<long long>(x);
    flow::str z = "any many";
    flow::str many = "";
    return 0;
}