// SPDX-FileCopyrightText: 2026 Klaus Reimer <k@ailis.de>
// SPDX-License-Identifier: MIT

#include "app.hpp"

#include <iostream>

int main(int argc, char** argv) {
    return app({ argv, argv + argc }, std::cout, std::cerr);
}
