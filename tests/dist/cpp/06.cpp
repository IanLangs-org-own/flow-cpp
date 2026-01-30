#include <flow/types>
#include <flow/io>

typedef struct { flow::str value; } strCopy;


int main() {
    strCopy obj;
    obj.value = "hola mundo";
    flow::println(obj.value);
    return 0;
}