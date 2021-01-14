#define __STDCPP_WANT_MATH_SPEC_FUNCS__ 1

// #include <iostream>
#include <cstdio>

#include <cmath>

int main() {
    // std::cout << std::assoc_legendre(1,1,0.5) << std::endl;
    printf("normal: %15.13lf\n", std::assoc_legendre(1,1,0.5));
    return 0;
}
