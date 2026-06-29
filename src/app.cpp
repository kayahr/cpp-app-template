// SPDX-FileCopyrightText: 2026 Klaus Reimer <k@ailis.de>
// SPDX-License-Identifier: MIT

#include "app.hpp"

#include <kayahr/library-template.hpp>

#include <cstdlib>
#include <ostream>

int app(std::vector<const char*> arguments, std::ostream& output, std::ostream& error_output) {
    if (arguments.size() != 3) {
        error_output << "Usage: app <a> <b>\n";
        return 1;
    }

    output << kayahr::library_template::sum(std::atoi(arguments[1]), std::atoi(arguments[2])) << '\n';
    return 0;
}
